//
//  Keychain+Promise.swift
//  BeamBiometricsKit
//
//  Created by Shane Whitehead on 16/10/18.
//  Copyright © 2018 BeamCommunications. All rights reserved.
//

import Foundation
import KeychainAccess
import Hydra

extension Keychain {
    func authenticate(withPrompt prompt: String, forKey key: String) -> Promise<Data?> {
        return Promise<Data?>(in: .userInitiated, { (fulfill, fail, _) in
            let data = try self.authenticationPrompt(prompt).getData(key)
            fulfill(data)
        })
    }
    
    func set(
        _ value: String,
        forKey key: String,
        withPrompt prompt: String,
        accessibility: Accessibility = .whenPasscodeSetThisDeviceOnly,
        authenticationPolicy: AuthenticationPolicy = .biometryCurrentSet
    ) -> Promise<Void> {
        return Promise<Void>(in: .userInitiated, { (fulfill, fail, _) in
            try self.accessibility(accessibility,
                                   authenticationPolicy: authenticationPolicy)
            .authenticationPrompt(prompt)
            .set(value, key: key)
            fulfill(())
        })
    }
    
    func set(
        _ data: Data,
        forKey key: String,
        withPrompt prompt: String,
        accessibility: Accessibility = .whenPasscodeSetThisDeviceOnly,
        authenticationPolicy: AuthenticationPolicy = .biometryCurrentSet
    ) -> Promise<Void> {
        return Promise<Void>(in: .userInitiated, { (fulfill, fail, _) in
            try self.accessibility(accessibility,
                                   authenticationPolicy: authenticationPolicy)
            .authenticationPrompt(prompt)
            .set(data, key: key)
            fulfill(())
        })
    }
}
