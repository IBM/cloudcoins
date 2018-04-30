import ARKit

class Pirate: SCNNode {
    func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "Pirate.scn") else { return }
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        addChildNode(wrapperNode)
    }
}

