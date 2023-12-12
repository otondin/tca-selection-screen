
import SwiftUI
import ComposableArchitecture
import IdentifiedCollections

public struct SingleSelectionFeature<Item: SelectableItemProtocol>: Reducer {
    
    @Dependency(\.dismiss) var dismiss

    public struct State: Equatable {
        var allItems: IdentifiedArrayOf<Item> = []
        var filteredItems: IdentifiedArrayOf<Item> = []
        var selectedItem: (Item)?

        @BindingState var itemsSearchText = ""

        public init(items: IdentifiedArrayOf<Item> = [], selectedItem: Item? = nil) {
            self.allItems = items
            self.selectedItem = selectedItem
        }

        func isItemSelected(_ item: Item) -> Bool {
            guard let selectedItem else { return false }

            return selectedItem.id == item.id
        }

        public var items: IdentifiedArrayOf<Item> {
            if itemsSearchText.isEmpty {
                return allItems
            } else {
                return filteredItems
            }
        }
    }

    public enum Action: Equatable, BindableAction {
        
        public enum Delegate: Equatable {
            case publish(Item?)
        }
        
        case dismiss
        case setSelectedItem(Item?)
        case doneButtonTapped
        case delegate(Delegate)
        case binding(BindingAction<State>)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .dismiss:
                return .run { _ in await dismiss() }

            case let .setSelectedItem(item):
                if state.selectedItem == item {
                    state.selectedItem = nil
                } else {
                    state.selectedItem = item
                }
                return .none

            case .doneButtonTapped:
                return .merge(
                    .send(.delegate(.publish(state.selectedItem))),
                    .run { _ in await dismiss() }
                )

            case .binding(\.$itemsSearchText):
                guard !state.itemsSearchText.isEmpty else {
                    return .none
                }

                state.filteredItems = state.allItems.filter { $0.title.lowercased().contains(state.itemsSearchText.lowercased()) }
                return .none
                
            case .delegate:
                // catch-all
                return .none

            case .binding:
                // catch-all
                return .none
            }
        }
    }
}
