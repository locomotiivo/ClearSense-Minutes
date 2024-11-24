//
//  OnnxManager.swift
//  backup_mpwav
//
//  Created by 이동건 on 2023/08/16.
//

import Foundation
import OnnxRuntimeBindings

import XCTest

class OnnxManager : XCTestCase {
    let modelPath: String = "onnx/mpANC.onnx"

    func testGetVersionString() throws {
        do {
            let version = ORTVersion()
            XCTAssertNotNil(version)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testCreateSession() throws {
        do {
            let env = try ORTEnv(loggingLevel: ORTLoggingLevel.verbose)
            let options = try ORTSessionOptions()
            try options.setLogSeverityLevel(ORTLoggingLevel.verbose)
            try options.setIntraOpNumThreads(1)
            // Create the ORTSession
            _ = try ORTSession(env: env, modelPath: modelPath, sessionOptions: options)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testAppendCoreMLEP() throws {
        do {
            let env = try ORTEnv(loggingLevel: ORTLoggingLevel.verbose)
            let sessionOptions: ORTSessionOptions = try ORTSessionOptions()
            let coreMLOptions: ORTCoreMLExecutionProviderOptions = ORTCoreMLExecutionProviderOptions()
            coreMLOptions.enableOnSubgraphs = true
            try sessionOptions.appendCoreMLExecutionProvider(with: coreMLOptions)

            XCTAssertTrue(ORTIsCoreMLExecutionProviderAvailable())
            _ = try ORTSession(env: env, modelPath: modelPath, sessionOptions: sessionOptions)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

    func testAppendXnnpackEP() throws {
        do {
            let env = try ORTEnv(loggingLevel: ORTLoggingLevel.verbose)
            let sessionOptions: ORTSessionOptions = try ORTSessionOptions()
            let XnnpackOptions: ORTXnnpackExecutionProviderOptions = ORTXnnpackExecutionProviderOptions()
            XnnpackOptions.intra_op_num_threads = 2
            try sessionOptions.appendXnnpackExecutionProvider(with: XnnpackOptions)

            XCTAssertTrue(ORTIsCoreMLExecutionProviderAvailable())
            _ = try ORTSession(env: env, modelPath: modelPath, sessionOptions: sessionOptions)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
