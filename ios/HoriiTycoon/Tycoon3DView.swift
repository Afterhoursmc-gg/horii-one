import SwiftUI
import SceneKit

struct Tycoon3DView: UIViewRepresentable {
    @ObservedObject var store: TycoonStore
    let scene: TycoonScene

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(); view.scene = scene; view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false; view.antialiasingMode = .multisampling4X
        view.backgroundColor = UIColor(red: 0.035, green: 0.05, blue: 0.09, alpha: 1)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        scene.setMap(store.selectedMap)
        view.scene = scene
    }
}
