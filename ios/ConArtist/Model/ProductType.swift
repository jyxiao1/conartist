//
//  ProductType.swift
//  ConArtist
//
//  Created by Cameron Eldridge on 2017-12-23.
//  Copyright © 2017 Cameron Eldridge. All rights reserved.
//

struct ProductType: Codable {
    let id: Int
    let name: String
    let color: Int
    let discontinued: Bool
    
    init?(graphQL type: ProductTypeFragment) {
        id = type.id
        name = type.name
        color = type.color ?? 0xFFFFFF
        discontinued = type.discontinued
    }
}
