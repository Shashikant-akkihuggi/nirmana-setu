const functions = require("firebase-functions");
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

try { admin.initializeApp(); } catch (e) {}
const db = admin.firestore();
const storage = admin.storage();

// Helpers
const Roles = Object.freeze({
  OWNER: 'owner',
  OWNER_CLIENT: 'ownerClient',
  ENGINEER: 'engineer',
  PROJECT_ENGINEER: 'projectEngineer',
  MANAGER: 'manager',
  FIELD_MANAGER: 'fieldManager',
  PURCHASE_MANAGER: 'purchaseManager',
});

const Status = Object.freeze({
  REQUESTED: 'REQUESTED',
  ENGINEER_APPROVED: 'ENGINEER_APPROVED',
  OWNER_APPROVED: 'OWNER_APPROVED',
  PO_CREATED: 'PO_CREATED',
  GRN_CONFIRMED: 'GRN_CONFIRMED',
  BILL_GENERATED: 'BILL_GENERATED',
  BILL_APPROVED: 'BILL_APPROVED',
});

function assert(condition, message) {
  if (!condition) {
    const err = new functions.https.HttpsError('failed-precondition', message);
    throw err;
  }
}

async function getUserRole(uid) {
  const doc = await db.collection('users').doc(uid).get();
  return doc.exists ? (doc.data().role || '') : '';
}

async function ensureProjectScope(projectId, uid, allowedRoles) {
  const project = await db.collection('projects').doc(projectId).get();
  assert(project.exists, 'Project not found');
  const data = project.data();
  assert(data.status === 'ACTIVE', 'Project not active');
  const role = await getUserRole(uid);
  assert(allowedRoles.includes(role), 'User role not permitted for this action');
  // basic membership check: user matches one of role ids
  const memberUids = [data.ownerId, data.engineerId, data.managerId, data.purchaseManagerId].filter(Boolean);
  assert(memberUids.includes(uid), 'User is not a member of this project');
  return { project: data, role };
}

function calculateGST({ baseAmount, gstRate, vendorStateCode, projectStateCode }) {
  const gstAmount = baseAmount * (gstRate / 100.0);
  const same = vendorStateCode && projectStateCode && vendorStateCode === projectStateCode;
  if (same || !vendorStateCode || !projectStateCode) {
    const half = gstAmount / 2.0;
    return { cgst: half, sgst: half, igst: 0 };
  }
  return { cgst: 0, sgst: 0, igst: gstAmount };
}

// 1) Material Request create by Field Manager
exports.createMaterialRequest = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  assert(uid, 'Unauthenticated');
  const { projectId, materials } = data;
  await ensureProjectScope(projectId, uid, [Roles.MANAGER, Roles.FIELD_MANAGER]);
  const mr = {
    projectId,
    createdBy: uid,
    materials: Array.isArray(materials) ? materials : [],
    status: Status.REQUESTED,
    engineerApproved: false,
    ownerApproved: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const ref = await db.collection('material_requests').add(mr);
  return { id: ref.id };
});

// 2) Engineer approves MR
exports.engineerApproveMR = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  assert(uid, 'Unauthenticated');
  const { mrId } = data;
  const doc = await db.collection('material_requests').doc(mrId).get();
  assert(doc.exists, 'MR not found');
  const mr = doc.data();
  await ensureProjectScope(mr.projectId, uid, [Roles.ENGINEER, Roles.PROJECT_ENGINEER]);
  assert(mr.status === Status.REQUESTED, 'Invalid MR status');
  await doc.ref.update({
    status: Status.ENGINEER_APPROVED,
    engineerApproved: true,
    engineerApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
    engineerId: uid,
  });
  return { ok: true };
});

// 3) Owner approves MR financially
exports.ownerApproveMR = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  assert(uid, 'Unauthenticated');
  const { mrId } = data;
  const doc = await db.collection('material_requests').doc(mrId).get();
  assert(doc.exists, 'MR not found');
  const mr = doc.data();
  await ensureProjectScope(mr.projectId, uid, [Roles.OWNER, Roles.OWNER_CLIENT]);
  assert(mr.status === Status.ENGINEER_APPROVED, 'Invalid MR status');
  await doc.ref.update({
    status: Status.OWNER_APPROVED,
    ownerApproved: true,
    ownerApprovedAt: admin.firestore.FieldValue.serverTimestamp(),
    ownerId: uid,
  });
  return { ok: true };
});

// 4) Purchase Manager creates PO only after Owner approval
exports.createPurchaseOrder = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  assert(uid, 'Unauthenticated');
  const { projectId, mrId, vendor, rateDetails, gstType } = data;
  await ensureProjectScope(projectId, uid, [Roles.PURCHASE_MANAGER]);
  const mrDoc = await db.collection('material_requests').doc(mrId).get();
  assert(mrDoc.exists, 'MR not found');
  const mr = mrDoc.data();
  assert(mr.projectId === projectId, 'Cross-project MR not allowed');
  assert(mr.status === Status.OWNER_APPROVED, 'MR must be OWNER_APPROVED');

  const po = {
    projectId,
    mrId,
    createdBy: uid,
    vendor,
    rateDetails: Array.isArray(rateDetails) ? rateDetails : [],
    gstType: gstType || 'CGST_SGST',
    status: Status.PO_CREATED,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const ref = await db.collection('purchase_orders').add(po);
  return { id: ref.id };
});

// 5) Field Manager confirms GRN
exports.confirmGRN = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  assert(uid, 'Unauthenticated');
  const { projectId, poId, receivedQty } = data;
  await ensureProjectScope(projectId, uid, [Roles.MANAGER, Roles.FIELD_MANAGER]);
  const poDoc = await db.collection('purchase_orders').doc(poId).get();
  assert(poDoc.exists, 'PO not found');
  const po = poDoc.data();
  assert(po.projectId === projectId, 'Cross-project PO not allowed');
  assert(po.status === Status.PO_CREATED, 'PO must be in PO_CREATED');

  const grn = {
    projectId,
    poId,
    verifiedBy: uid,
    receivedQty: receivedQty || {},
    status: Status.GRN_CONFIRMED,
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const ref = await db.collection('grn').add(grn);
  return { id: ref.id };
});

// 6) Engineer approves bills (after creation)
exports.approveBill = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  assert(uid, 'Unauthenticated');
  const { billId } = data;
  const billDoc = await db.collection('bills').doc(billId).get();
  assert(billDoc.exists, 'Bill not found');
  const bill = billDoc.data();
  await ensureProjectScope(bill.projectId, uid, [Roles.ENGINEER, Roles.PROJECT_ENGINEER]);
  assert(bill.status === 'BILL_GENERATED', 'Bill must be BILL_GENERATED');
  await billDoc.ref.update({
    status: 'BILL_APPROVED',
    engineerApproved: true,
    approvedBy: uid,
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});

// 7) Create Bill (manual or OCR) => auto GST calculation
exports.createBill = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  assert(uid, 'Unauthenticated');
  const { projectId, poId, grnId, source, vendorGSTIN, taxableAmount, gstRate, vendorStateCode, projectStateCode, pdfUrl } = data;

  await ensureProjectScope(projectId, uid, [Roles.MANAGER, Roles.FIELD_MANAGER]);

  // Validations
  assert(poId && grnId, 'Bill must reference PO and GRN');
  const poDoc = await db.collection('purchase_orders').doc(poId).get();
  assert(poDoc.exists, 'PO not found');
  const grnDoc = await db.collection('grn').doc(grnId).get();
  assert(grnDoc.exists, 'GRN not found');
  const po = poDoc.data();
  const grn = grnDoc.data();
  assert(po.projectId === projectId && grn.projectId === projectId, 'Cross-project references not allowed');
  assert(grn.status === Status.GRN_CONFIRMED, 'GRN must be confirmed');

  // GST Calculation server-side
  const gst = calculateGST({ baseAmount: taxableAmount, gstRate, vendorStateCode, projectStateCode });
  const totalAmount = taxableAmount + gst.cgst + gst.sgst + gst.igst;

  const bill = {
    projectId,
    poId,
    grnId,
    source: source || 'MANUAL',
    vendorGSTIN,
    taxableAmount,
    cgst: parseFloat(gst.cgst.toFixed(2)),
    sgst: parseFloat(gst.sgst.toFixed(2)),
    igst: parseFloat(gst.igst.toFixed(2)),
    totalAmount: parseFloat(totalAmount.toFixed(2)),
    status: 'BILL_GENERATED',
    pdfUrl: pdfUrl || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const ref = await db.collection('bills').add(bill);
  return { id: ref.id, ...bill };
});

// 8) HTTP endpoint to generate PDF and upload to Storage, then patch bill
exports.generateBillPdf = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  assert(uid, 'Unauthenticated');
  const { billId } = data;
  const doc = await db.collection('bills').doc(billId).get();
  assert(doc.exists, 'Bill not found');
  const bill = doc.data();
  await ensureProjectScope(bill.projectId, uid, [Roles.ENGINEER, Roles.MANAGER, Roles.FIELD_MANAGER, Roles.OWNER, Roles.OWNER_CLIENT]);

  // Here we would generate a PDF server-side using a Node PDF lib. For brevity, we create a placeholder file.
  const bucket = storage.bucket();
  const tmp = Buffer.from(`GST Invoice for bill ${billId} - total ${bill.totalAmount}`);
  const filename = `bills/${bill.projectId}/${billId}.pdf`;
  const file = bucket.file(filename);
  await file.save(tmp, { contentType: 'application/pdf', resumable: false, metadata: { metadata: { firebaseStorageDownloadTokens: uuidv4() } } });
  const [url] = await file.getSignedUrl({ action: 'read', expires: '03-09-2491' });
  await doc.ref.update({ pdfUrl: url });
  return { pdfUrl: url };
});

// 9) Storage Trigger for OCR (async, non-blocking)
exports.onBillImageUpload = functions.storage.object().onFinalize(async (object) => {
  const filePath = object.name; // storage/bills/{projectId}/{billId}.jpg
  if (!filePath || !filePath.startsWith('bills/')) return;
  const parts = filePath.split('/');
  if (parts.length < 3) return;
  const projectId = parts[1];
  const filename = parts[2];
  const billId = filename.split('.')[0];

  // Perform OCR - integrate with a proper OCR service; here we simulate with placeholders.
  const ocrData = {
    extracted: true,
    vendorGSTIN: 'PLACEHOLDERGSTIN',
    taxableAmount: 0,
  };

  await db.collection('bills').doc(billId).set({
    projectId,
    ocrRawData: ocrData,
    source: 'OCR',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
});

// 10) Backwards-compatible placeholder for older endpoint
exports.generateConcept = functions.https.onRequest(async (req, res) => {
  res.json({ status: 'ok' });
});
