import Foundation

public protocol SelectableItemProtocol: Identifiable & Hashable & Equatable {
    var id: String { get }
    var title: String { get }
}
