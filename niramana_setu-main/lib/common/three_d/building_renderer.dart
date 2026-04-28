/// Building Renderer - Enhanced Three.js Rendering Logic
/// 
/// This class generates the Three.js scene setup with:
/// - Realistic lighting (directional sun, ambient, hemisphere)
/// - High-quality materials (PBR with roughness/metalness)
/// - Soft shadows
/// - Optimized render settings
/// 
/// Why separate this?
/// - Lighting and materials can be tweaked independently
/// - Easy to add new visual effects
/// - Render quality settings in one place
/// - Future: could support multiple render modes (realistic, wireframe, etc.)
class BuildingRenderer {
  /// Generate complete Three.js scene initialization code
  /// 
  /// This creates the renderer, lighting, materials, and scene setup.
  /// The actual geometry is added separately by the building model.
  static String generateSceneSetup() {
    return '''
    // ============================================
    // SCENE INITIALIZATION
    // ============================================
    
    function initScene() {
      // Scene with soft sky background
      scene = new THREE.Scene();
      scene.background = new THREE.Color(0xe8f1f5); // Soft blue-gray sky
      scene.fog = new THREE.Fog(0xe8f1f5, 40, 180); // Atmospheric depth
      
      return scene;
    }
    
    // ============================================
    // LIGHTING SYSTEM - Realistic & Warm
    // ============================================
    
    function initLighting(scene) {
      // 1. Ambient Light - Soft fill light (simulates sky bounce)
      const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
      scene.add(ambientLight);
      
      // 2. Directional Light - Main sun (warm, from upper-right)
      const sunLight = new THREE.DirectionalLight(0xfff4e0, 1.4);
      sunLight.position.set(50, 100, 60);
      sunLight.castShadow = true;
      
      // High-quality shadow configuration
      sunLight.shadow.mapSize.width = 2048;
      sunLight.shadow.mapSize.height = 2048;
      sunLight.shadow.camera.near = 0.5;
      sunLight.shadow.camera.far = 250;
      sunLight.shadow.bias = -0.0003; // Reduce shadow acne
      sunLight.shadow.normalBias = 0.02;
      
      // Shadow frustum (covers large area)
      const shadowSize = 60;
      sunLight.shadow.camera.left = -shadowSize;
      sunLight.shadow.camera.right = shadowSize;
      sunLight.shadow.camera.top = shadowSize;
      sunLight.shadow.camera.bottom = -shadowSize;
      
      scene.add(sunLight);
      
      // 3. Hemisphere Light - Sky vs Ground color difference
      const hemiLight = new THREE.HemisphereLight(
        0xffffff, // Sky color (white)
        0x8d9ba3, // Ground color (cool gray)
        0.4
      );
      hemiLight.position.set(0, 50, 0);
      scene.add(hemiLight);
      
      // 4. Subtle fill light from opposite side (prevents harsh shadows)
      const fillLight = new THREE.DirectionalLight(0xe3f2fd, 0.3);
      fillLight.position.set(-30, 40, -40);
      scene.add(fillLight);
      
      return { sunLight, ambientLight, hemiLight, fillLight };
    }
    
    // ============================================
    // MATERIAL LIBRARY - PBR Materials
    // ============================================
    
    function createMaterials() {
      return {
        // Ground plane - Light concrete texture
        ground: new THREE.MeshStandardMaterial({
          color: 0xeceff1,
          roughness: 0.95,
          metalness: 0.0,
          envMapIntensity: 0.3
        }),
        
        // Plot base - Slightly darker concrete
        plotBase: new THREE.MeshStandardMaterial({
          color: 0xdfe3e6,
          roughness: 0.85,
          metalness: 0.05,
          envMapIntensity: 0.4
        }),
        
        // Setback zone - Transparent green overlay
        setback: new THREE.MeshBasicMaterial({
          color: 0x66bb6a,
          transparent: true,
          opacity: 0.12,
          side: THREE.DoubleSide,
          depthWrite: false
        }),
        
        // Building exterior - Clean white with subtle texture
        buildingExterior: new THREE.MeshStandardMaterial({
          color: 0xfafafa,
          roughness: 0.45,
          metalness: 0.08,
          envMapIntensity: 0.6
        }),
        
        // Building accent - Slightly darker for contrast
        buildingAccent: new THREE.MeshStandardMaterial({
          color: 0xf5f5f5,
          roughness: 0.50,
          metalness: 0.10
        }),
        
        // Glass windows - Reflective with transparency
        glass: new THREE.MeshPhysicalMaterial({
          color: 0xb3e5fc,
          metalness: 0.1,
          roughness: 0.1,
          transparent: true,
          opacity: 0.4,
          transmission: 0.6,
          thickness: 0.5,
          envMapIntensity: 1.2
        }),
        
        // Roof/terrace - Matte finish
        roof: new THREE.MeshStandardMaterial({
          color: 0xf0f0f0,
          roughness: 0.92,
          metalness: 0.02
        }),
        
        // Edge lines - Subtle gray
        edges: new THREE.LineBasicMaterial({
          color: 0x90a4ae,
          opacity: 0.4,
          transparent: true,
          linewidth: 1
        }),
        
        // Plot border - Darker outline
        plotBorder: new THREE.LineBasicMaterial({
          color: 0x37474f,
          opacity: 0.8,
          transparent: true,
          linewidth: 2
        })
      };
    }
    
    // ============================================
    // RENDERER CONFIGURATION - High Quality
    // ============================================
    
    function initRenderer() {
      const renderer = new THREE.WebGLRenderer({
        antialias: true,
        alpha: false,
        powerPreference: 'high-performance'
      });
      
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // Cap at 2x for performance
      
      // Enable shadows
      renderer.shadowMap.enabled = true;
      renderer.shadowMap.type = THREE.PCFSoftShadowMap; // Soft shadows
      
      // Color management
      renderer.outputEncoding = THREE.sRGBEncoding;
      renderer.toneMapping = THREE.ACESFilmicToneMapping;
      renderer.toneMappingExposure = 1.1; // Slightly brighter
      
      // Physical light units
      renderer.physicallyCorrectLights = true;
      
      document.body.appendChild(renderer.domElement);
      
      return renderer;
    }
    
    // ============================================
    // HELPER FUNCTIONS
    // ============================================
    
    function addGroundPlane(scene, materials) {
      // Infinite ground with subtle grid
      const groundSize = 600;
      const groundPlane = new THREE.Mesh(
        new THREE.PlaneGeometry(groundSize, groundSize),
        materials.ground
      );
      groundPlane.rotation.x = -Math.PI / 2;
      groundPlane.position.y = -0.25;
      groundPlane.receiveShadow = true;
      scene.add(groundPlane);
      
      // Grid helper - very subtle
      const grid = new THREE.GridHelper(groundSize, 120, 0xcfd8dc, 0xe8f1f5);
      grid.position.y = -0.24;
      grid.material.transparent = true;
      grid.material.opacity = 0.35;
      scene.add(grid);
      
      return { groundPlane, grid };
    }
    
    function addPlotBase(scene, materials, model) {
      // The land plot
      const plotGeo = new THREE.BoxGeometry(model.plotWidth, 0.15, model.plotLength);
      const plotMesh = new THREE.Mesh(plotGeo, materials.plotBase);
      plotMesh.position.y = -0.075;
      plotMesh.castShadow = false;
      plotMesh.receiveShadow = true;
      scene.add(plotMesh);
      
      // Plot border (darker outline)
      const plotEdges = new THREE.LineSegments(
        new THREE.EdgesGeometry(plotGeo),
        materials.plotBorder
      );
      plotEdges.position.copy(plotMesh.position);
      scene.add(plotEdges);
      
      // Setback visualization (green overlay)
      const setbackGeo = new THREE.PlaneGeometry(model.plotWidth, model.plotLength);
      const setbackMesh = new THREE.Mesh(setbackGeo, materials.setback);
      setbackMesh.rotation.x = -Math.PI / 2;
      setbackMesh.position.y = 0.03;
      setbackMesh.renderOrder = 1; // Render after ground
      scene.add(setbackMesh);
      
      return { plotMesh, plotEdges, setbackMesh };
    }
    ''';
  }
  
  /// Generate building geometry creation code
  /// 
  /// This creates the actual 3D building based on the model parameters.
  /// Includes floors, windows, roof, and architectural details.
  static String generateBuildingGeometry() {
    return '''
    // ============================================
    // BUILDING GEOMETRY - Data-Driven
    // ============================================
    
    function createBuilding(scene, materials, model) {
      const buildingGroup = new THREE.Group();
      buildingGroup.name = 'building';
      
      const bWidth = model.buildingWidth;
      const bLength = model.buildingLength;
      const floorH = model.floorHeight;
      
      // Create each floor
      for (let i = 0; i < model.floors; i++) {
        const floorGroup = createFloor(materials, bWidth, bLength, floorH, i);
        buildingGroup.add(floorGroup);
      }
      
      // Add roof/terrace
      const roof = createRoof(materials, bWidth, bLength, model.totalHeight);
      buildingGroup.add(roof);
      
      scene.add(buildingGroup);
      return buildingGroup;
    }
    
    function createFloor(materials, width, length, height, floorIndex) {
      const floorGroup = new THREE.Group();
      const yPos = (floorIndex * height) + (height / 2);
      
      // Main floor box
      const floorGeo = new THREE.BoxGeometry(width, height - 0.12, length);
      const floorMesh = new THREE.Mesh(floorGeo, materials.buildingExterior);
      floorMesh.position.y = yPos;
      floorMesh.castShadow = true;
      floorMesh.receiveShadow = true;
      floorGroup.add(floorMesh);
      
      // Floor slab (horizontal separator between floors)
      const slabGeo = new THREE.BoxGeometry(width + 0.2, 0.15, length + 0.2);
      const slabMesh = new THREE.Mesh(slabGeo, materials.buildingAccent);
      slabMesh.position.y = yPos - (height / 2) + 0.075;
      slabMesh.castShadow = true;
      slabMesh.receiveShadow = true;
      floorGroup.add(slabMesh);
      
      // Windows (simplified - 4 sides)
      addWindows(floorGroup, materials, width, length, height, yPos);
      
      // Subtle edge lines
      const edges = new THREE.LineSegments(
        new THREE.EdgesGeometry(floorGeo),
        materials.edges
      );
      edges.position.copy(floorMesh.position);
      floorGroup.add(edges);
      
      return floorGroup;
    }
    
    function addWindows(floorGroup, materials, width, length, height, yPos) {
      const windowHeight = height * 0.6;
      const windowWidth = 1.2;
      const windowDepth = 0.08;
      const windowSpacing = 2.5;
      
      // Front and back walls (along length)
      for (let side = 0; side < 2; side++) {
        const zPos = side === 0 ? length / 2 : -length / 2;
        const numWindows = Math.floor(width / windowSpacing);
        
        for (let i = 0; i < numWindows; i++) {
          const xPos = (i - numWindows / 2) * windowSpacing + windowSpacing / 2;
          const window = new THREE.Mesh(
            new THREE.BoxGeometry(windowWidth, windowHeight, windowDepth),
            materials.glass
          );
          window.position.set(xPos, yPos, zPos);
          window.castShadow = false;
          window.receiveShadow = false;
          floorGroup.add(window);
        }
      }
      
      // Left and right walls (along width)
      for (let side = 0; side < 2; side++) {
        const xPos = side === 0 ? width / 2 : -width / 2;
        const numWindows = Math.floor(length / windowSpacing);
        
        for (let i = 0; i < numWindows; i++) {
          const zPos = (i - numWindows / 2) * windowSpacing + windowSpacing / 2;
          const window = new THREE.Mesh(
            new THREE.BoxGeometry(windowDepth, windowHeight, windowWidth),
            materials.glass
          );
          window.position.set(xPos, yPos, zPos);
          window.castShadow = false;
          window.receiveShadow = false;
          floorGroup.add(window);
        }
      }
    }
    
    function createRoof(materials, width, length, totalHeight) {
      const roofGeo = new THREE.BoxGeometry(width + 0.3, 0.25, length + 0.3);
      const roofMesh = new THREE.Mesh(roofGeo, materials.roof);
      roofMesh.position.y = totalHeight + 0.125;
      roofMesh.castShadow = true;
      roofMesh.receiveShadow = false;
      
      return roofMesh;
    }
    ''';
  }
}
