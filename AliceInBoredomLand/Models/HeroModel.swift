//
//  HeroModel.swift
//  AliceInBoredomLand
//
//  Created by Wijaya William on 5/4/25.
//

import SpriteKit

struct HeroModel {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector = .zero
    var health: Int
    var attack: Int
    var speed: CGFloat
    var manaCost: Int
    var tilePosition: Int = 0
    var physics: PhysicsComponent
    var knockbackTimer: TimeInterval = 0
    var lastAttackTime: TimeInterval = 0
    var attackCooldown: TimeInterval = 0.1
    var attackRange: CGFloat = 500
    var type: HeroType
}

struct HeroStats {
    let manaCost: Int
    let attack: Int
    let health: Int
    let speed: CGFloat
    let bitmask: UInt32
}

enum HeroType {
    case swordsman, archer, tank
}

extension HeroModel: Renderable {
    var renderSpec: RenderSpec {
        RenderSpec(
            textureName: getName(),
            size: physics.size,
            position: position,
            zPosition: 1,
            name: getName()
        )
    }

    private func getName() -> String {
        switch type {
        case .archer:
            return "archer"
        case .swordsman:
            return "swordsman"
        case .tank:
            return "tank"
        }
    }

}

extension HeroModel: PhysicsBodySpecProvider {
    var physicsBodySpec: PhysicsComponent {
        physics
    }
}
