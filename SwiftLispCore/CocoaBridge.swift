//
//  CocoaBridge.swift
//  SwiftLisp
//
//  Created by Rod Schmidt on 5/24/19.
//  Copyright © 2019 infiniteNIL. All rights reserved.
//

import Foundation

// Objective-C type encodings
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html

struct ObjCRuntime {

    func lookupClass(_ name: String) -> AnyClass? {
        return objc_lookUpClass(name)
    }

    func callMethod(_ methodName: String, target: AnyObject, with args: [(key: String, value: Any?)]) throws -> Any? {
        let selectorString = args.reduce(methodName) { $0 + $1.key + ":" }
        let selector = sel_getUid(selectorString)

        guard let method = getMethod(target: target, selector: selector) else { return nil }
        let result = try call(selector: selector, method: method, target: target, args: args)
        return convertResult(result, method: method,
                             shouldRelease: shouldReleaseResult(of: selectorString))
    }

    private func getMethod(target: AnyObject, selector: Selector) -> Method? {
        if target is AnyClass {
            return class_getClassMethod(target as? AnyClass, selector)
        }
        else {
            return class_getInstanceMethod(type(of: target), selector)
        }
    }

    private func shouldReleaseResult(of selector: String) -> Bool {
        return selector.starts(with: "alloc")
            || selector.starts(with: "init")
            || selector.starts(with: "new")
            || selector.starts(with: "copy")
    }

    private func call(selector: Selector, method: Method, target: AnyObject?, args: [(key: String, value: Any?)]) throws -> UnsafeRawPointer? {
        typealias M0 = @convention(c) (AnyObject?, Selector) -> UnsafeRawPointer?
        typealias M1WithObject = @convention(c) (AnyObject?, Selector, AnyObject?) -> UnsafeRawPointer?
        typealias M1WithNonObject = @convention(c) (AnyObject?, Selector, Any) -> UnsafeRawPointer?
        // TODO: methods with more arguments
        // TODO: Methods with arguments of other types

        let argCount = method_getNumberOfArguments(method)
        guard argCount - 2 == args.count else { throw SwiftLispError.arityMismatch }

        let impl = method_getImplementation(method)

        let result : UnsafeRawPointer?
        switch args.count {
        case 0:
            let typedMethod = unsafeBitCast(impl, to: M0.self)
            result = typedMethod(target, selector)

        case 1:
            let argType = argumentType(method: method, index: 2)
            switch argType {
            case "@":
                let typedMethod = unsafeBitCast(impl, to: M1WithObject.self)
                result = typedMethod(target, selector, args[0].value as AnyObject)

            case "Q":
                typealias M1Q = @convention(c) (AnyObject?, Selector, CUnsignedLongLong) -> UnsafeRawPointer?
                let typedMethod = unsafeBitCast(impl, to: M1Q.self)
                result = typedMethod(target, selector, args[0].value as! CUnsignedLongLong)

            default:
                fatalError("Can't handle argument type \(argType) yet")
            }

        default:
            fatalError("can't do that count yet!")
        }

        return result
    }

    private func convertResult(_ result: UnsafeRawPointer?, method: Method, shouldRelease: Bool) -> Any? {
        let returnType = self.returnType(for: method)
        switch returnType {
        case "@":
            guard let result = result else { return nil }
            let p = Unmanaged<AnyObject>.fromOpaque(result)
            if shouldRelease {
                return p.takeRetainedValue()
            }
            else {
                return p.takeUnretainedValue()
            }

        case "Q":
            return unsafeBitCast(result, to: CUnsignedLongLong.self)

        case "c":
            let i = unsafeBitCast(result, to: Int.self)
            return CChar(i)

        case "S":
            let i = unsafeBitCast(result, to: Int.self)
            return Character(UnicodeScalar(Int(i))!)

        default:
            fatalError("Can't handle \(returnType) return type yet")
        }
    }

    private func returnType(for method: Method) -> String {
        var buf = [Int8](repeating: 0, count: 46)
        method_getReturnType(method, &buf, buf.count)
        return String(cString: &buf)
    }

    private func argumentType(method: Method, index: Int) -> String {
        var buf = [Int8](repeating: 0, count: 46)
        method_getArgumentType(method, UInt32(index), &buf, buf.count)
        return String(cString: &buf)
    }

}

