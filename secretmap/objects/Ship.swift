import ARKit

class Ship: SCNNode {
    func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "Ship.scn") else { return }
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        addChildNode(wrapperNode)
    }
}

