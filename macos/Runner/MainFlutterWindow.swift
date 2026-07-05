import Cocoa
import FlutterMacOS
import CoreVideo
import IOSurface

// Swift-to-Rust C-FFI direct symbol bindings
@_silgen_name("synapse_bevy_init_viewport")
func synapse_bevy_init_viewport(_ viewport_id: UInt64, _ width: UInt32, _ height: UInt32) -> UInt64

@_silgen_name("synapse_bevy_resize_viewport")
func synapse_bevy_resize_viewport(_ viewport_id: UInt64, _ width: UInt32, _ height: UInt32)

@_silgen_name("synapse_bevy_render_frame")
func synapse_bevy_render_frame(_ viewport_id: UInt64, _ out_pixels: UnsafeMutableRawPointer)

@_silgen_name("synapse_bevy_update_nodes")
func synapse_bevy_update_nodes(_ json_ptr: UnsafePointer<Int8>)

@_silgen_name("synapse_bevy_update_angles")
func synapse_bevy_update_angles(_ h_angle: Double, _ v_angle: Double)

class MainFlutterWindow: NSWindow {
  private var bevyTextures: [Int64: BevyTexture] = [:]
  private var displayLink: CVDisplayLink?
  private var flutterViewController: FlutterViewController?

  override func awakeFromNib() {
    let viewController = FlutterViewController()
    self.flutterViewController = viewController
    let windowFrame = self.frame
    self.contentViewController = viewController
    self.setFrame(windowFrame, display: true)
    
    // Set window background color to matching dark theme to prevent white flashes during resize redraws
    self.backgroundColor = NSColor(red: 9.0/255.0, green: 10.0/255.0, blue: 15.0/255.0, alpha: 1.0)

    RegisterGeneratedPlugins(registry: viewController)

    // Setup MethodChannel for Bevy Viewport Texture sharing
    let channel = FlutterMethodChannel(
      name: "synapse/viewport",
      binaryMessenger: viewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      let registry = viewController.engine as FlutterTextureRegistry
      
      switch call.method {
      case "initTexture":
        guard let args = call.arguments as? [String: Any],
              let width = args["width"] as? Int,
              let height = args["height"] as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: "Width and height required", details: nil))
          return
        }
        
        let bevyTexture = BevyTexture()
        if bevyTexture.allocate(width: width, height: height) {
          let textureId = registry.register(bevyTexture)
          bevyTexture.textureId = textureId
          self.bevyTextures[textureId] = bevyTexture
          
          // Trigger Rust FFI viewport initialization!
          let iosurfaceId = bevyTexture.getIOSurfaceID()
          let viewportHandle = synapse_bevy_init_viewport(UInt64(textureId), UInt32(width), UInt32(height))
          
          // Start the Display Link if it's the first texture!
          if self.bevyTextures.count == 1 {
            self.startDisplayLink()
          }
          
          result([
            "textureId": textureId,
            "iosurfaceId": iosurfaceId,
            "viewportHandle": viewportHandle
          ])
        } else {
          result(FlutterError(code: "ALLOC_FAILED", message: "Failed to allocate CVPixelBuffer", details: nil))
        }
        
      case "resizeTexture":
        guard let args = call.arguments as? [String: Any],
              let textureId = args["textureId"] as? Int64,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: "textureId, width, and height required", details: nil))
          return
        }
        
        guard let bevyTexture = self.bevyTextures[textureId] else {
          result(FlutterError(code: "NOT_FOUND", message: "Texture not found", details: nil))
          return
        }
        
        if bevyTexture.allocate(width: width, height: height) {
          let iosurfaceId = bevyTexture.getIOSurfaceID()
          
          // Trigger Rust FFI viewport resizing!
          synapse_bevy_resize_viewport(UInt64(textureId), UInt32(width), UInt32(height))
          
          registry.textureFrameAvailable(textureId)
          result([
            "iosurfaceId": iosurfaceId
          ])
        } else {
          result(FlutterError(code: "ALLOC_FAILED", message: "Failed to resize CVPixelBuffer", details: nil))
        }
        
      case "updateNodes":
        guard let args = call.arguments as? [String: Any],
              let nodesJson = args["nodes"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "nodes JSON string required", details: nil))
          return
        }
        
        // Pass JSON string over C-FFI to Rust!
        synapse_bevy_update_nodes(nodesJson)
        result(nil)
        
      case "updateAngles":
        guard let args = call.arguments as? [String: Any],
              let hAngle = args["hAngle"] as? Double,
              let vAngle = args["vAngle"] as? Double else {
          result(FlutterError(code: "INVALID_ARGS", message: "hAngle and vAngle required", details: nil))
          return
        }
        
        // Pass horizontal and vertical orbit angles to Rust!
        synapse_bevy_update_angles(hAngle, vAngle)
        result(nil)
        
      case "disposeTexture":
        guard let args = call.arguments as? [String: Any],
              let textureId = args["textureId"] as? Int64 else {
          result(FlutterError(code: "INVALID_ARGS", message: "textureId required", details: nil))
          return
        }
        
        if let bevyTexture = self.bevyTextures.removeValue(forKey: textureId) {
          bevyTexture.deallocate()
          registry.unregisterTexture(textureId)
        }
        
        // Stop the Display Link if no active textures remain!
        if self.bevyTextures.isEmpty {
          self.stopDisplayLink()
        }
        
        result(nil)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  // High precision CVDisplayLink VSync loop
  private func startDisplayLink() {
    guard displayLink == nil else { return }
    
    let status = CVDisplayLinkCreateWithCGDisplay(CGMainDisplayID(), &displayLink)
    if status != kCVReturnSuccess {
      print("[Swift] Error: Failed to create CVDisplayLink")
      return
    }
    
    let callback: CVDisplayLinkOutputCallback = { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext) -> CVReturn in
      let window = Unmanaged<MainFlutterWindow>.fromOpaque(displayLinkContext!).takeUnretainedValue()
      window.renderNextFrame()
      return kCVReturnSuccess
    }
    
    CVDisplayLinkSetOutputCallback(displayLink!, callback, Unmanaged.passUnretained(self).toOpaque())
    CVDisplayLinkStart(displayLink!)
    print("[Swift] CVDisplayLink VSync loop started successfully at 120Hz ProMotion.")
  }

  private func stopDisplayLink() {
    if let dl = displayLink {
      CVDisplayLinkStop(dl)
      displayLink = nil
      print("[Swift] CVDisplayLink VSync loop stopped cleanly.")
    }
  }

  // Core VSync-locked render step with Double Buffering Pointer Swap
  func renderNextFrame() {
    let registry = flutterViewController?.engine as? FlutterTextureRegistry
    
    for (textureId, bevyTexture) in bevyTextures {
      // 1. Rust ALWAYS writes directly into the BACK BUFFER (completely isolated!)
      guard let pb = bevyTexture.getBackBuffer() else { continue }
      
      // 2. Lock back buffer memory base address to draw pixels on Unified Memory
      CVPixelBufferLockBaseAddress(pb, [])
      if let outPixels = CVPixelBufferGetBaseAddress(pb) {
        
        // 3. Direct FFI call into Rust to draw the 3D scene directly into BACK BUFFER
        synapse_bevy_render_frame(UInt64(textureId), outPixels)
      }
      CVPixelBufferUnlockBaseAddress(pb, [])
      
      // 4. Thread-safely SWAP front/back buffers! (Back becomes Front, Front becomes Back)
      bevyTexture.swapBuffers()
      
      // 5. Dispatch to main thread to signal Flutter compositor that a new perfect Front Buffer is ready
      DispatchQueue.main.async { [weak self] in
        guard self != nil else { return }
        registry?.textureFrameAvailable(textureId)
      }
    }
  }
}

// ====================================================================
// Swift External Texture Host Class with Double Buffering Support
// ====================================================================

class BevyTexture: NSObject, FlutterTexture {
    var textureId: Int64 = -1
    private var pixelBufferA: CVPixelBuffer?
    private var pixelBufferB: CVPixelBuffer?
    
    // Double buffering index (0: A is Front, B is Back; 1: B is Front, A is Back)
    private var frontBufferIndex: Int = 0
    private let bufferLock = NSLock()
    
    private(set) var width: Int = 0
    private(set) var height: Int = 0

    func allocate(width: Int, height: Int) -> Bool {
        self.width = width
        self.height = height
        deallocate()

        let attributes: [CFString: Any] = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
        ]

        var pbA: CVPixelBuffer?
        var pbB: CVPixelBuffer?
        
        let statusA = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pbA
        )
        let statusB = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pbB
        )

        if statusA != kCVReturnSuccess || statusB != kCVReturnSuccess {
            return false
        }
        
        bufferLock.lock()
        self.pixelBufferA = pbA
        self.pixelBufferB = pbB
        self.frontBufferIndex = 0
        bufferLock.unlock()
        return true
    }

    // Returns the Back Buffer that Rust is allowed to write into asynchronously
    func getBackBuffer() -> CVPixelBuffer? {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        return frontBufferIndex == 0 ? pixelBufferB : pixelBufferA
    }

    // Returns the Front Buffer that Flutter is allowed to read from synchronously
    func getFrontBuffer() -> CVPixelBuffer? {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        return frontBufferIndex == 0 ? pixelBufferA : pixelBufferB
    }

    // Instantly performs a zero-overhead pointer swap
    func swapBuffers() {
        bufferLock.lock()
        frontBufferIndex = 1 - frontBufferIndex
        bufferLock.unlock()
    }

    func getIOSurfaceID() -> UInt32 {
        guard let pb = getFrontBuffer() else { return 0 }
        guard let unmanagedSurface = CVPixelBufferGetIOSurface(pb) else { return 0 }
        let surface = unmanagedSurface.takeUnretainedValue()
        return IOSurfaceGetID(surface)
    }

    func deallocate() {
        bufferLock.lock()
        self.pixelBufferA = nil
        self.pixelBufferB = nil
        bufferLock.unlock()
    }

    // Flutter call to get the current static frame buffer (Flutter reads from FRONT buffer!)
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if let pb = getFrontBuffer() {
            return Unmanaged.passRetained(pb)
        }
        return nil
    }
}
