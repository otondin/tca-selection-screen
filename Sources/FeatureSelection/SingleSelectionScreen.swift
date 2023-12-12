
import SwiftUI
import ComposableArchitecture
import IdentifiedCollections
import Models
import ComponentLibrary
import Localization

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

        var items: IdentifiedArrayOf<Item> {
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

public struct SingleSelectionScreen<Item: SelectableItemProtocol>: View {
    let store: StoreOf<SingleSelectionFeature<Item>>

    public init(store: StoreOf<SingleSelectionFeature<Item>>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        if viewStore.items.isEmpty {
                            Spacer()
                            ProgressView()
                            Spacer()
                        } else {
                            list
                        }
                    }
                    .padding(Spacing.padding2)
                }
                .fullBleedBackground(Color.Semantic.primaryBackground)
                .navigationTitle("Select Item")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CircleButton(
                            description: L10n.General.dismiss,
                            style: .secondary,
                            icon: {
                                Image(systemName: "chevron.down")
                            },
                            action: {
                                viewStore.send(.dismiss)
                            }
                        )
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        TextButton(
                            title: L10n.General.done,
                            action: {
                                viewStore.send(.doneButtonTapped)
                            }
                        )
                        .disabled(viewStore.selectedItem == nil ? true : false)
                    }
                }
            }
            .searchable(text: viewStore.$itemsSearchText)
        }
    }

    private var list: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: Spacing.padding2) {
                ForEach(viewStore.items) { item in
                    HStack {
                        Text(item.title)
                        Spacer()
                        if viewStore.state.isItemSelected(item) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewStore.send(.setSelectedItem(item))
                    }
                    Divider()
                }
            }
        }
    }
}

struct SingleSelectionScreen_Preview: PreviewProvider {
    static var previews: some View {
        SingleSelectionScreen<SelfInspection>(
            store: Store(
                initialState: SingleSelectionFeature<SelfInspection>.State(
                    items: .init(uniqueElements: [])
                ),
                reducer: {
                    SingleSelectionFeature()
                }
            )
        )
    }
}
