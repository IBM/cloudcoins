import ARKit

class Treasure: SCNNode {
    func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "Treasure.scn") else { return }
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        addChildNode(wrapperNode)
    }
}

