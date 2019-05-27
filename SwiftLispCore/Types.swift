
class DataType: Equatable {
    var metadata: DataType?

    init(metadata: DataType? = nil) {
        self.metadata = metadata
    }

    func copy() -> DataType {
        return DataType(metadata: metadata)
    }

    static func ==(_ lhs: DataType, _ rhs: DataType) -> Bool {
        if let lhs = lhs as? Symbol, let rhs = rhs as? Symbol {
            return lhs == rhs
        }
        else if let lhs = lhs as? Keyword, let rhs = rhs as? Keyword {
            return lhs == rhs
        }
        else if let lhs = lhs as? LispString, let rhs = rhs as? LispString {
            return lhs == rhs
        }
        else if let lhs = lhs as? Number, let rhs = rhs as? Number {
            return lhs == rhs
        }
        else if let lhs = lhs as? List, let rhs = rhs as? List {
            return lhs == rhs
        }
        else if let lhs = lhs as? Vector, let rhs = rhs as? Vector {
            return lhs == rhs
        }
        else if let lhs = lhs as? List, let rhs = rhs as? Vector {
            return lhs == rhs
        }
        else if let lhs = lhs as? Vector, let rhs = rhs as? List {
            return lhs == rhs
        }
        else if let lhs = lhs as? HashMap, let rhs = rhs as? HashMap {
            return lhs == rhs
        }
        else if lhs === Nil, rhs === Nil {
            return true
        }
        else if let lhs = lhs as? Boolean, let rhs = rhs as? Boolean {
            return lhs == rhs
        }

        return false
    }

    var isTruthy: Bool {
        switch self {
        case let b as Boolean:  return b.isTrue
        case Nil:               return false
        default:                return true
        }
    }

    var isPair: Bool {
        if let list = self as? List {
            return !list.elements.isEmpty
        }
        else if let v = self as? Vector {
            return !v.elements.isEmpty
        }
        else {
            return false
        }
    }

}

protocol Collection {
    var isEmpty: Bool { get }
    var asList: List { get }
}

class List: DataType, Collection {
    var elements: [DataType] = []

    init() {}

    init(_ elements: [DataType]) {
        self.elements = elements
    }

    init(_ elements: ArraySlice<DataType>) {
        self.elements = Array(elements)
    }

    var isEmpty: Bool { return elements.isEmpty }

    var asList: List { return self }

    override func copy() -> DataType {
        let result = List()
        result.elements = elements
        return result
    }

    func append(_ element: DataType) {
        elements.append(element)
    }

    static func ==(_ lhs: List, _ rhs: List) -> Bool {
        guard lhs.elements.count == rhs.elements.count else { return false }

        for i in 0..<lhs.elements.count {
            if lhs.elements[i] != rhs.elements[i] {
                return false
            }
        }

        return true
    }

    static func ==(_ lhs: List, _ rhs: Vector) -> Bool {
        guard lhs.elements.count == rhs.elements.count else { return false }

        for i in 0..<lhs.elements.count {
            if lhs.elements[i] != rhs.elements[i] {
                return false
            }
        }

        return true
    }
}

class Vector: DataType, Collection {
    private(set) var elements: [DataType] = []

    init() {}

    init(_ elements: [DataType]) {
        self.elements = elements
    }

    init(_ elements: ArraySlice<DataType>) {
        self.elements = Array(elements)
    }

    var isEmpty: Bool { return elements.isEmpty }

    var asList: List { return List(elements) }

    override func copy() -> DataType {
        let result = Vector()
        result.elements = elements
        return result
    }

    func append(_ element: DataType) {
        elements.append(element)
    }

    static func ==(_ lhs: Vector, _ rhs: Vector) -> Bool {
        guard lhs.elements.count == rhs.elements.count else { return false }

        for i in 0..<lhs.elements.count {
            if lhs.elements[i] != rhs.elements[i] {
                return false
            }
        }

        return true
    }

    static func ==(_ lhs: Vector, _ rhs: List) -> Bool {
        guard lhs.elements.count == rhs.elements.count else { return false }

        for i in 0..<lhs.elements.count {
            if lhs.elements[i] != rhs.elements[i] {
                return false
            }
        }

        return true
    }
}

class HashMap: DataType, Collection {
    // Hash are stored with like this [key value key value....]
    private(set) var elements: [DataType] = []

    var isEmpty: Bool { return elements.isEmpty }

    var asList: List {
        return List(elements)
    }

    override func copy() -> DataType {
        let result = HashMap()
        result.elements = elements
        return result
    }

    func append(_ element: DataType) {
        elements.append(element)
    }

    static func ==(_ lhs: HashMap, _ rhs: HashMap) -> Bool {
        guard lhs.elements.count == rhs.elements.count else { return false }

        for i in stride(from: 0, to: lhs.elements.count, by: 2) {
            guard let rhsValue = rhs.get(lhs.elements[i]) else { return false }
            if lhs.elements[i + 1] != rhsValue {
                return false
            }
        }

        return true
    }

    func get(_ key: DataType) -> DataType? {
        for i in stride(from: 0, to: elements.count, by: 2) {
            if key == elements[i] {
                return elements[i + 1]
            }
        }

        return nil
    }

    func remove(_ key: DataType) {
        guard let index = elements.firstIndex(of: key) else { return }
        elements.removeSubrange(index...(index + 1))
    }
}

class Number: DataType {
    let value: Int

    init(_ value: Int) {
        self.value = Int(value)
        super.init()
    }

    override func copy() -> DataType {
        return Number(value)
    }

    static func==(_ lhs: Number, _ rhs: Number) -> Bool {
        return lhs.value == rhs.value
    }
}

class LispString: DataType, Collection {
    let value: String

    init(_ value: String) {
        self.value = value
        super.init()
    }

    var isEmpty: Bool { return value.isEmpty }

    var asList: List {
        return List(value.map { LispString(String($0)) })
    }

    override func copy() -> DataType {
        return LispString(value)
    }

    static func==(_ lhs: LispString, _ rhs: LispString) -> Bool {
        return lhs.value == rhs.value
    }
}

class Symbol: DataType, Hashable {
    let name: String

    init(_ name: String) {
        self.name = name
        super.init()
    }

    init(_ name: LispString) {
        self.name = name.value
        super.init()
    }

    override func copy() -> DataType {
        return Symbol(name)
    }

    static func==(_ lhs: Symbol, _ rhs: Symbol) -> Bool {
        return lhs.name == rhs.name
    }

    static func==(_ lhs: Symbol, _ rhs: String) -> Bool {
        return lhs.name == rhs
    }

    static func==(_ lhs: String, _ rhs: Symbol) -> Bool {
        return lhs == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        return name.hash(into: &hasher)
    }
}

class Atom: DataType {
    var value: DataType

    init(value: DataType) {
        self.value = value
        super.init()
    }

    override func copy() -> DataType {
        return Atom(value: value)
    }
}

class Keyword: DataType {
    let name: String

    init(_ name: String) {
        self.name = name
        super.init()
    }

    init(_ name: LispString) {
        self.name = name.value
        super.init()
    }

    override func copy() -> DataType {
        return Keyword(name)
    }

    static func==(_ lhs: Keyword, _ rhs: Keyword) -> Bool {
        return lhs.name == rhs.name
    }
}

class Function: DataType {
    let name: String?
    let ast: DataType?
    let params: [Symbol]?
    let env: Environment?
    let fn: ([DataType]) throws -> DataType
    var isMacro: Bool

    init(name: String? = nil, ast: DataType? = nil, params: [Symbol]? = nil, env: Environment? = nil, isMacro: Bool = false, metadata: DataType = Nil, fn: @escaping ([DataType]) throws -> DataType) {
        self.name = name
        self.ast = ast
        self.params = params
        self.env = env
        self.fn = fn
        self.isMacro = isMacro
        super.init(metadata: metadata)
    }

    override func copy() -> DataType {
        return Function(name: name,
                        ast: ast,
                        params: params,
                        env: env,
                        isMacro: isMacro,
                        metadata: metadata ?? Nil,
                        fn: fn)
    }
}

let Nil = NilType.instance

class NilType: DataType {
    static let instance = NilType()

    private init() {}

    static func==(_ lhs: NilType, _ rhs: NilType) -> Bool {
        return true
    }

    override func copy() -> DataType {
        return self
    }
}

extension NilType: CustomStringConvertible {
    var description: String { return "nil" }
}

class Boolean: DataType {
    static let True = Boolean(true)
    static let False = Boolean(false)

    private let value: Bool

    private init(_ value: Bool) {
        self.value = value
        super.init()
    }

    var isTrue: Bool { return self === Boolean.True }
    var isFalse: Bool { return self === Boolean.False }

    static func eval(_ condition: Bool) -> Boolean {
        return condition ? True : False
    }

    static func not(_ condition: Bool) -> Boolean {
        return condition ? False : True
    }

    override func copy() -> DataType {
        return self
    }

    static func==(_ lhs: Boolean, _ rhs: Boolean) -> Bool {
        return lhs === rhs
    }
}

extension Boolean: CustomStringConvertible {
    var description: String {
        return self === Boolean.True ? "true" : "false"
    }
}
