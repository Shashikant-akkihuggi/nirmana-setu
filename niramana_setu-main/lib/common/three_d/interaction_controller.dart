/// Interaction Controller - User Interaction & Animation Loop
/// 
/// This class manages:
/// - Main render loop
/// - Animation frame updates
/// - Performance monitoring
/// - User interaction events
/// 
/// Why separate this?
/// - Clean animation loop management
/// - Easy to add performance optimizations
/// - Interaction events in one place
/// - Future: could add interaction modes (measure, annotate, etc.)
class InteractionController {
  /// Generate main animation loop
  /// 
  /// This is the heart of the 3D visualization - runs every frame
  /// to update controls and render the scene.
  static String generateAnimationLoop() {
    return '''
    // ============================================
    // ANIMATION LOOP - Render Engine
    // ============================================
    
    let frameCount = 0;
    let lastTime = performance.now();
    let fps = 60;
    
    function animate() {
      requestAnimationFrame(animate);
      
      // Update FPS counter (for debugging)
      frameCount++;
      const currentTime = performance.now();
      if (currentTime >= lastTime + 1000) {
        fps = Math.round((frameCount * 1000) / (currentTime - lastTime));
        frameCount = 0;
        lastTime = currentTime;
        // console.log('FPS:', fps); // Uncomment for debugging
      }
      
      // Update controls (handles damping/inertia)
      if (controls) {
        controls.update();
      }
      
      // Render scene
      if (renderer && scene && camera) {
        renderer.render(scene, camera);
      }
    }
    
    // ============================================
    // PERFORMANCE OPTIMIZATION
    // ============================================
    
    function optimizePerformance() {
      // Reduce pixel ratio on lower-end devices
      const pixelRatio = window.devicePixelRatio;
      if (pixelRatio > 2) {
        renderer.setPixelRatio(2); // Cap at 2x
      }
      
      // Adjust shadow quality based on device
      if (pixelRatio < 2) {
        // Lower shadow quality on lower-end devices
        const lights = scene.children.filter(child => child.isDirectionalLight);
        lights.forEach(light => {
          if (light.shadow) {
            light.shadow.mapSize.width = 1024;
            light.shadow.mapSize.height = 1024;
          }
        });
      }
    }
    ''';
  }
  
  /// Generate interaction event handlers
  /// 
  /// Handles user interactions beyond basic orbit controls.
  static String generateInteractionHandlers() {
    return '''
    // ============================================
    // INTERACTION HANDLERS
    // ============================================
    
    let isInteracting = false;
    let interactionTimeout = null;
    
    function setupInteractionHandlers(renderer, controls) {
      const canvas = renderer.domElement;
      
      // Track interaction state
      canvas.addEventListener('pointerdown', onInteractionStart);
      canvas.addEventListener('pointerup', onInteractionEnd);
      canvas.addEventListener('pointermove', onInteractionMove);
      canvas.addEventListener('wheel', onWheel);
      
      // Touch events
      canvas.addEventListener('touchstart', onInteractionStart, { passive: true });
      canvas.addEventListener('touchend', onInteractionEnd, { passive: true });
      canvas.addEventListener('touchmove', onInteractionMove, { passive: true });
    }
    
    function onInteractionStart(event) {
      isInteracting = true;
      clearTimeout(interactionTimeout);
      
      // Optional: Show interaction feedback
      // document.body.style.cursor = 'grabbing';
    }
    
    function onInteractionEnd(event) {
      // Delay marking interaction as ended (for smooth transitions)
      interactionTimeout = setTimeout(() => {
        isInteracting = false;
        // document.body.style.cursor = 'grab';
      }, 100);
    }
    
    function onInteractionMove(event) {
      if (isInteracting) {
        // Optional: Custom interaction logic here
        // For now, OrbitControls handles everything
      }
    }
    
    function onWheel(event) {
      // Zoom interaction detected
      isInteracting = true;
      clearTimeout(interactionTimeout);
      interactionTimeout = setTimeout(() => {
        isInteracting = false;
      }, 150);
    }
    
    // ============================================
    // DOUBLE-TAP TO RESET VIEW
    // ============================================
    
    let lastTapTime = 0;
    
    function setupDoubleTapReset(camera, controls, model) {
      document.addEventListener('touchend', (event) => {
        const currentTime = Date.now();
        const tapGap = currentTime - lastTapTime;
        
        if (tapGap < 300 && tapGap > 0) {
          // Double tap detected - reset to default view
          setCameraPreset(camera, controls, 'corner', model);
        }
        
        lastTapTime = currentTime;
      });
    }
    
    // ============================================
    // KEYBOARD SHORTCUTS (Optional)
    // ============================================
    
    function setupKeyboardShortcuts(camera, controls, model) {
      document.addEventListener('keydown', (event) => {
        switch(event.key) {
          case '1':
            setCameraPreset(camera, controls, 'front', model);
            break;
          case '2':
            setCameraPreset(camera, controls, 'right', model);
            break;
          case '3':
            setCameraPreset(camera, controls, 'back', model);
            break;
          case '4':
            setCameraPreset(camera, controls, 'left', model);
            break;
          case '5':
            setCameraPreset(camera, controls, 'top', model);
            break;
          case '0':
            setCameraPreset(camera, controls, 'corner', model);
            break;
          case 'r':
          case 'R':
            // Toggle auto-rotate
            controls.autoRotate = !controls.autoRotate;
            break;
        }
      });
    }
    ''';
  }
  
  /// Generate loading state management
  static String generateLoadingState() {
    return '''
    // ============================================
    // LOADING STATE MANAGEMENT
    // ============================================
    
    function hideLoadingIndicator() {
      const info = document.getElementById('info');
      if (info) {
        info.style.transition = 'opacity 0.3s';
        info.style.opacity = '0';
        setTimeout(() => info.style.display = 'none', 300);
      }
    }
    
    function showLoadingIndicator(message = 'Loading...') {
      const info = document.getElementById('info');
      if (info) {
        info.textContent = message;
        info.style.display = 'block';
        info.style.opacity = '1';
      }
    }
    
    function updateLoadingProgress(progress, message) {
      const info = document.getElementById('info');
      if (info) {
        info.textContent = \`\${message} \${Math.round(progress * 100)}%\`;
      }
    }
    ''';
  }
}
