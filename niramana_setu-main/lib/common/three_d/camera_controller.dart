/// Camera Controller - Interactive Camera & Gesture Handling
/// 
/// This class manages:
/// - Camera positioning and perspective
/// - Orbit controls (rotate, zoom, pan)
/// - Smooth animations and damping
/// - Responsive camera adjustments
/// 
/// Why separate this?
/// - Camera logic independent of scene/geometry
/// - Easy to add new camera modes (top-down, first-person, etc.)
/// - Gesture handling in one place
/// - Future: could support camera presets or guided tours
class CameraController {
  /// Generate camera initialization code
  /// 
  /// Creates a perspective camera with optimal positioning
  /// for architectural visualization.
  static String generateCameraSetup(String modelVar) {
    return '''
    // ============================================
    // CAMERA SETUP - Perspective View
    // ============================================
    
    function initCamera($modelVar) {
      // Perspective camera with natural FOV
      const camera = new THREE.PerspectiveCamera(
        45, // FOV - natural perspective (not too wide, not too narrow)
        window.innerWidth / window.innerHeight,
        0.5, // Near clipping plane
        300  // Far clipping plane
      );
      
      // Calculate optimal camera position based on building size
      const buildingSize = Math.max($modelVar.buildingWidth, $modelVar.buildingLength);
      const buildingHeight = $modelVar.totalHeight;
      
      // Position camera at elevated corner view (classic architectural angle)
      const distance = buildingSize * 2.2;
      const elevation = buildingHeight + Math.max(buildingHeight * 0.8, 15);
      
      camera.position.set(
        distance * 0.85,  // X: slightly to the side
        elevation,         // Y: elevated view
        distance * 0.85   // Z: diagonal view
      );
      
      // Look at building center (slightly above ground)
      camera.lookAt(0, buildingHeight * 0.35, 0);
      
      return camera;
    }
    
    // ============================================
    // ORBIT CONTROLS - Smooth Interaction
    // ============================================
    
    function initControls(camera, renderer, $modelVar) {
      const controls = new THREE.OrbitControls(camera, renderer.domElement);
      
      // Smooth damping (inertia effect)
      controls.enableDamping = true;
      controls.dampingFactor = 0.06; // Smooth but responsive
      
      // Enable all interaction modes
      controls.enableRotate = true;  // Drag to rotate
      controls.enableZoom = true;    // Pinch/scroll to zoom
      controls.enablePan = true;     // Two-finger drag to pan
      
      // Rotation constraints
      controls.minPolarAngle = 0.1; // Prevent camera from going too low
      controls.maxPolarAngle = Math.PI / 2 - 0.05; // Prevent going below ground
      
      // Zoom constraints (based on building size)
      const buildingSize = Math.max($modelVar.buildingWidth, $modelVar.buildingLength);
      controls.minDistance = buildingSize * 0.5; // Don't get too close
      controls.maxDistance = buildingSize * 5;   // Don't get too far
      
      // Pan constraints (keep building in view)
      controls.maxPanSpeed = 2.0;
      controls.panSpeed = 1.0;
      
      // Target point (what camera orbits around)
      controls.target.set(0, $modelVar.totalHeight * 0.35, 0);
      
      // Auto-rotate (optional - disabled by default)
      controls.autoRotate = false;
      controls.autoRotateSpeed = 0.5;
      
      // Touch interaction settings
      controls.touches = {
        ONE: THREE.TOUCH.ROTATE,    // One finger = rotate
        TWO: THREE.TOUCH.DOLLY_PAN  // Two fingers = zoom + pan
      };
      
      // Mouse button settings
      controls.mouseButtons = {
        LEFT: THREE.MOUSE.ROTATE,   // Left click = rotate
        MIDDLE: THREE.MOUSE.DOLLY,  // Middle click = zoom
        RIGHT: THREE.MOUSE.PAN      // Right click = pan
      };
      
      return controls;
    }
    
    // ============================================
    // CAMERA PRESETS - Quick Views
    // ============================================
    
    function setCameraPreset(camera, controls, preset, $modelVar) {
      const size = Math.max($modelVar.buildingWidth, $modelVar.buildingLength);
      const height = $modelVar.totalHeight;
      const distance = size * 2.2;
      
      let newPosition;
      let newTarget = new THREE.Vector3(0, height * 0.35, 0);
      
      switch(preset) {
        case 'front':
          newPosition = new THREE.Vector3(0, height * 0.6, distance);
          break;
        case 'back':
          newPosition = new THREE.Vector3(0, height * 0.6, -distance);
          break;
        case 'left':
          newPosition = new THREE.Vector3(-distance, height * 0.6, 0);
          break;
        case 'right':
          newPosition = new THREE.Vector3(distance, height * 0.6, 0);
          break;
        case 'top':
          newPosition = new THREE.Vector3(0, height * 2.5, size * 0.5);
          newTarget = new THREE.Vector3(0, 0, 0);
          break;
        case 'corner':
        default:
          newPosition = new THREE.Vector3(distance * 0.85, height + 15, distance * 0.85);
          break;
      }
      
      // Smooth transition to new position
      animateCameraTo(camera, controls, newPosition, newTarget);
    }
    
    function animateCameraTo(camera, controls, targetPosition, targetLookAt, duration = 1000) {
      const startPosition = camera.position.clone();
      const startTarget = controls.target.clone();
      const startTime = Date.now();
      
      function animate() {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        // Smooth easing (ease-in-out)
        const eased = progress < 0.5
          ? 2 * progress * progress
          : 1 - Math.pow(-2 * progress + 2, 2) / 2;
        
        // Interpolate position
        camera.position.lerpVectors(startPosition, targetPosition, eased);
        controls.target.lerpVectors(startTarget, targetLookAt, eased);
        
        controls.update();
        
        if (progress < 1) {
          requestAnimationFrame(animate);
        }
      }
      
      animate();
    }
    
    // ============================================
    // RESPONSIVE HANDLING
    // ============================================
    
    function onWindowResize(camera, renderer) {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    }
    ''';
  }
  
  /// Generate gesture hint overlay (optional UI element)
  static String generateGestureHints() {
    return '''
    // ============================================
    // GESTURE HINTS - User Guidance
    // ============================================
    
    function showGestureHints() {
      const hints = document.createElement('div');
      hints.id = 'gesture-hints';
      hints.style.cssText = `
        position: absolute;
        bottom: 80px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0, 0, 0, 0.75);
        color: white;
        padding: 12px 20px;
        border-radius: 20px;
        font-family: 'Segoe UI', sans-serif;
        font-size: 11px;
        pointer-events: none;
        opacity: 0;
        transition: opacity 0.3s;
        z-index: 100;
      `;
      hints.innerHTML = '🖱️ Drag to rotate • 🔍 Scroll to zoom • ⌨️ Right-click to pan';
      document.body.appendChild(hints);
      
      // Show hints briefly on load
      setTimeout(() => hints.style.opacity = '1', 500);
      setTimeout(() => hints.style.opacity = '0', 4000);
      setTimeout(() => hints.remove(), 4500);
    }
    ''';
  }
}
