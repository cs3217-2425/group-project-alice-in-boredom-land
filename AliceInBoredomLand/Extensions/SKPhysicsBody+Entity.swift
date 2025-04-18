//
//  SKPhysicsBody+Entity.swift
//  AliceInBoredomLand
//
//  Created by Wijaya William on 19/3/25.
//

import SpriteKit
import ObjectiveC

private var entityKey: UInt8 = 0

extension SKPhysicsBody {
    var entity: LevelEntity? {
        get { objc_getAssociatedObject(self, &entityKey) as? LevelEntity }
        set { objc_setAssociatedObject(self, &entityKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
