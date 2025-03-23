//
//  GameScene.swift
//  AliceInBoredomLand
//
//  Created by Wijaya William on 17/3/25.
//

import SpriteKit

class GameScene: SKScene {
    var gameLogicDelegate: GameLogicDelegate
    var entities: [GameEntity] = []
    var tasks: [Task] = []
    var frameCounter = 0

    let tileSize = CGSize(width: height / Double(numRows), height: width / Double(numCols))

    init(gameLogicDelegate: GameLogicDelegate,
         background: SKColor = .gray,
         size: CGSize = CGSize(width: GameScene.width, height: GameScene.height)) {
        self.gameLogicDelegate = gameLogicDelegate
        self.entities = []
        super.init(size: size)
        self.backgroundColor = background
        self.scaleMode = .aspectFit
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(_ currentTime: TimeInterval) {
        frameCounter += 1

        if frameCounter.isMultiple(of: 30) {
            performFrameLogic()
        }

        updateProjectiles()
    }

    private func performFrameLogic() {
        let deltaTime: TimeInterval = 1.0
        let frameIndex = frameCounter / 30

        if frameIndex % 2 == 1 {
            entities.compactMap { $0 as? Hero }.forEach { $0.update(deltaTime: deltaTime) }
        } else {
            entities.compactMap { $0 as? Monster }.forEach { $0.update(deltaTime: deltaTime) }
        }

        tasks.forEach { $0.update(deltaTime: deltaTime) }

        if frameIndex % 8 == 1 {
            spawnTask()
        }

        checkWinLose()
        removeDeadEntities()
    }

    private func updateProjectiles() {
        entities.compactMap { $0 as? Arrow }.forEach { $0.updateArrow(deltaTime: 1.0) }
    }

    private func checkWinLose() {
        guard let logic = gameLogicDelegate as? GameLogic else {
            return
        }

        if logic.monsterCastleHealth <= 0 {
            showEndGameLabel(text: "You Win 🎉")
            isPaused = true
            return
        }

        if logic.playerCastleHealth <= 0 {
            showEndGameLabel(text: "You Lose 💀")
            isPaused = true
            return
        }
    }

    private func showEndGameLabel(text: String) {
        let label = SKLabelNode(text: text)
        label.fontSize = 50
        label.fontColor = .white
        label.fontName = "Avenir-Heavy"
        label.position = CGPoint(x: GameScene.width / 2, y: GameScene.height / 2 + 50)
        label.name = "end_game_label"
        addChild(label)

        let restartLabel = SKLabelNode(text: "Tap to Restart")
        restartLabel.fontSize = 30
        restartLabel.fontColor = .yellow
        restartLabel.fontName = "Avenir"
        restartLabel.position = CGPoint(x: GameScene.width / 2, y: GameScene.height / 2 - 50)
        restartLabel.name = "restart_button"
        addChild(restartLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPaused else {
            return
        }

        for touch in touches {
            let location = touch.location(in: self)
            if let node = self.atPoint(location) as? SKLabelNode, node.name == "restart_button" {
                restartGame()
            }
        }
    }

    private func restartGame() {
        guard let view = self.view else {
            return
        }

        let newLogic = GameLogic()
        let newScene = GameScene(gameLogicDelegate: newLogic)
        newScene.scaleMode = self.scaleMode
        view.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.5))
    }

    func spawnHero(atX tileX: Int, atY tileY: Int = 5, type: String = "hero") {
        assert(0 < tileX && tileX < GameScene.numCols - 1)
        assert(1 < tileY && tileY < GameScene.numRows)

        guard let logic = gameLogicDelegate as? GameLogic else {
            return
        }

        let typeLowercased = type.lowercased()
        let texture = SKTexture(imageNamed: typeLowercased)

        let hero: Hero = {
            switch typeLowercased {
            case "archer":
                return Archer(texture: texture, size: tileSize)
            case "tank":
                return Tank(texture: texture, size: tileSize)
            case "swordsman":
                return Swordsman(texture: texture, size: tileSize)
            default:
                return Swordsman(texture: texture, size: tileSize)
            }
        }()

        guard logic.mana >= hero.manaCost else {
            print("Not enough mana to spawn \(typeLowercased)")
            return
        }

        logic.decreaseMana(by: hero.manaCost)

        hero.position = CGPoint(
            x: (CGFloat(tileX) + 0.5) * tileSize.width,
            y: (CGFloat(tileY) + 0.5) * tileSize.height
        )

        let bitmask: UInt32 = {
            switch typeLowercased {
            case "archer":
                return BitMask.Hero.archer
            case "tank":
                return BitMask.Hero.tanker
            case "swordsman":
                return BitMask.Hero.swordsman
            default:
                return BitMask.Hero.swordsman
            }
        }()

        let body = SKPhysicsBody(rectangleOf: tileSize)
        body.affectedByGravity = false
        body.isDynamic = true
        body.categoryBitMask = bitmask

        addChild(hero)
        entities.append(hero)
    }

    private func spawnMonster(atX tileX: Int, atY tileY: Int = 5) {
        assert(0 < tileX && tileX < GameScene.numCols - 1)
        assert(1 < tileY && tileY < GameScene.numRows)

        let texture = SKTexture(imageNamed: "monster")
        let monster = Monster(texture: texture, size: tileSize, health: 100, attack: 20, speed: 40.0)

        monster.position = CGPoint(x: (CGFloat(tileX) + 1 / 2) * tileSize.width,
                                   y: (CGFloat(tileY) + 1 / 2) * tileSize.height)

        monster.physicsBody = SKPhysicsBody(rectangleOf: tileSize)
        monster.physicsBody?.affectedByGravity = false
        monster.physicsBody?.isDynamic = true
        monster.physicsBody?.categoryBitMask = BitMask.Monster.titan
        monster.physicsBody?.contactTestBitMask = BitMask.Hero.archer | BitMask.Hero.swordsman | BitMask.Hero.tanker

        addChild(monster)
        entities.append(monster)
    }

    private func spawnPlayerCastle() {
        let texture = SKTexture(imageNamed: "player-castle")
        let size = CGSize(width: tileSize.width, height: tileSize.height * 5)
        let playerCastle = GameCastle(texture: texture, size: size, isPlayer: true)

        playerCastle.position = CGPoint(x: 1 / 2 * tileSize.width, y: 4.5 * tileSize.height)

        playerCastle.physicsBody = SKPhysicsBody(rectangleOf: size)
        playerCastle.physicsBody?.affectedByGravity = false
        playerCastle.physicsBody?.isDynamic = false

        addChild(playerCastle)
        entities.append(playerCastle)
    }

    private func spawnEnemyCastle() {
        let texture = SKTexture(imageNamed: "enemy-castle")
        let size = CGSize(width: tileSize.width, height: tileSize.height * 5)
        let enemyCastle = GameCastle(texture: texture, size: size, isPlayer: false)

        enemyCastle.position = CGPoint(x: (CGFloat(GameScene.numCols) - 2.5) * tileSize.width,
                                       y: 4.5 * tileSize.height)

        enemyCastle.physicsBody = SKPhysicsBody(rectangleOf: size)
        enemyCastle.physicsBody?.affectedByGravity = false
        enemyCastle.physicsBody?.isDynamic = false

        addChild(enemyCastle)
        entities.append(enemyCastle)
    }

    private func spawnTask() {
        let texture = SKTexture(imageNamed: "task")
        let task = Task(texture: texture, size: tileSize)

        task.position = CGPoint(x: (CGFloat(GameScene.numCols) - 1 / 2) * tileSize.width, y: 1 * tileSize.height)

        task.physicsBody = SKPhysicsBody(rectangleOf: tileSize)
        task.physicsBody?.affectedByGravity = false
        task.physicsBody?.isDynamic = true
        task.physicsBody?.categoryBitMask = BitMask.Task.task
        task.physicsBody?.contactTestBitMask = BitMask.Task.task

        addChild(task)
        tasks.append(task)
    }

    private func removeDeadEntities() {
        entities = entities.filter { entity in
            if !entity.isAlive {
                entity.node.removeFromParent()
                return false
            }
            return true
        }
    }

    func initialiseEntities() {
        spawnPlayerCastle()
        spawnEnemyCastle()
//        spawnMonster(atX: 8)
        spawnMonster(atX: 3, atY: 3)
    }

    private func handleCollisions() {
    }

    override func didMove(to view: SKView) {
        initialiseEntities()
        physicsWorld.contactDelegate = self
    }
}

extension GameScene {
    func isMonsterInRange(_ archerPosition: CGPoint, range: CGFloat) -> Bool {
        let monsters = entities.compactMap { $0 as? Monster }

        for monster in monsters {
            let distance = (monster.position - archerPosition).length()
            if distance <= range {
                return true
            }
        }
        return false
    }
}
