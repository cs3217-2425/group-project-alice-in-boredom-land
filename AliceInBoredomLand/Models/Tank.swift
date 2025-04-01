//
//  Tank.swift
//  AliceInBoredomLand
//
//  Created by Wijaya William on 21/3/25.
//

import SpriteKit

class Tank: OldHero {
    override init(texture: SKTexture, size: CGSize,
                  health: Int = 200, attack: Int = 2, speed: CGFloat = 20, manaCost: Int = 20) {
        super.init(texture: texture, size: size,
                   health: health, attack: attack, speed: speed, manaCost: manaCost)
        self.physicsBody?.categoryBitMask = OldBitMask.Hero.tank
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
