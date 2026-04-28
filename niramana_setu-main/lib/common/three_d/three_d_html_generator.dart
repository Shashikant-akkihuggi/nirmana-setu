import 'building_model.dart';
import 'building_renderer.dart';
import 'camera_controller.dart';
import 'interaction_controller.dart';

/// Three.js HTML Generator - Assembles Complete 3D Visualization
/// 
/// This class orchestrates all the separate modules into a complete
/// HTML page with embedded Three.js visualization.
/// 
/// Why this architecture?
/// - Clean separation of concerns (geometry, rendering, camera, interaction)
/// - Easy to modify individual aspects without touching others
/// - Testable components
/// - AI-ready: parameters can be injected at any level
/// - Scalable: new features can be added as new modules
class ThreeDHtmlGenerator {
  /// Generate complete HTML with embedded Three.js visualization
  /// 
  /// This assembles all the modules into a working 3D scene.
  static String generateHtml(BuildingModel model) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>3D Building Concept</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      margin: 0;
      overflow: hidden;
      background-color: #e8f1f5;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      touch-action: none; /* Prevent default touch behaviors */
    }
    
    canvas {
      display: block;
      outline: none;
      touch-action: none;
    }
    
    #info {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: rgba(255, 255, 255, 0.95);
      color: #333;
      padding: 20px 30px;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1.5px;
      pointer-events: none;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
      z-index: 1000;
    }
    
    #info::after {
      content: '';
      position: absolute;
      bottom: -8px;
      left: 50%;
      transform: translateX(-50%);
      width: 40px;
      height: 3px;
      background: linear-gradient(90deg, #136DEC, #7A5AF8);
      border-radius: 2px;
    }
  </style>
</head>
<body>
  <div id="info">Initializing 3D Concept...</div>
  
  <!-- Three.js Library -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
  
  <script>
    // ============================================
    // GLOBAL VARIABLES
    // ============================================
    
    let scene, camera, renderer, controls;
    let buildingGroup;
    
    // Building model data (from Flutter)
    const model = ${model.toJavaScript()};
    
    console.log('Building Model:', model);
    
    // ============================================
    // INITIALIZATION
    // ============================================
    
    function init() {
      console.log('Initializing 3D scene...');
      
      // 1. Create scene
      ${BuildingRenderer.generateSceneSetup()}
      scene = initScene();
      
      // 2. Setup lighting
      ${BuildingRenderer.generateSceneSetup()}
      const lights = initLighting(scene);
      
      // 3. Create materials
      ${BuildingRenderer.generateSceneSetup()}
      const materials = createMaterials();
      
      // 4. Initialize renderer
      ${BuildingRenderer.generateSceneSetup()}
      renderer = initRenderer();
      
      // 5. Setup camera
      ${CameraController.generateCameraSetup('model')}
      camera = initCamera(model);
      
      // 6. Setup controls
      ${CameraController.generateCameraSetup('model')}
      controls = initControls(camera, renderer, model);
      
      // 7. Build scene geometry
      ${BuildingRenderer.generateSceneSetup()}
      addGroundPlane(scene, materials);
      addPlotBase(scene, materials, model);
      
      ${BuildingRenderer.generateBuildingGeometry()}
      buildingGroup = createBuilding(scene, materials, model);
      
      // 8. Setup interactions
      ${InteractionController.generateInteractionHandlers()}
      setupInteractionHandlers(renderer, controls);
      setupDoubleTapReset(camera, controls, model);
      
      // Optional: Keyboard shortcuts (disabled by default)
      // setupKeyboardShortcuts(camera, controls, model);
      
      // 9. Optimize performance
      ${InteractionController.generateAnimationLoop()}
      optimizePerformance();
      
      // 10. Setup responsive handling
      ${CameraController.generateCameraSetup('model')}
      window.addEventListener('resize', () => onWindowResize(camera, renderer));
      
      // 11. Show gesture hints
      ${CameraController.generateGestureHints()}
      showGestureHints();
      
      // 12. Hide loading indicator
      ${InteractionController.generateLoadingState()}
      setTimeout(() => hideLoadingIndicator(), 500);
      
      console.log('3D scene initialized successfully');
    }
    
    // ============================================
    // ANIMATION LOOP
    // ============================================
    
    ${InteractionController.generateAnimationLoop()}
    
    // ============================================
    // START APPLICATION
    // ============================================
    
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        init();
        animate();
      });
    } else {
      init();
      animate();
    }
    
  </script>
</body>
</html>
    ''';
  }
  
  /// Generate a simplified version for testing/debugging
  static String generateDebugHtml(BuildingModel model) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Debug View</title>
  <style>
    body { margin: 0; background: #f0f0f0; font-family: monospace; }
    #debug { position: absolute; top: 10px; left: 10px; background: white; padding: 10px; }
  </style>
</head>
<body>
  <div id="debug">
    <h3>Building Model Debug</h3>
    <pre>${model.toString()}</pre>
    <pre>Plot: ${model.plotWidth}m x ${model.plotLength}m</pre>
    <pre>Building: ${model.buildingWidth}m x ${model.buildingLength}m</pre>
    <pre>Floors: ${model.floors} (${model.totalHeight}m total)</pre>
    <pre>Style: ${model.facadeStyle}</pre>
    <pre>Roof: ${model.roofType}</pre>
  </div>
</body>
</html>
    ''';
  }
}
