import Foundation

import SwiftUI
import ComposableArchitecture
import IdentifiedCollections
import Models
import ComponentLibrary
import Localization

public struct MultiSelectionFeature<Item: SelectableItemProtocol>: Reducer {
    
    @Dependency(\.dismiss) var dismiss

    public struct State: Equatable {
        var allItems: IdentifiedArrayOf<Item> = []
        var filteredItems: IdentifiedArrayOf<Item> = []
        var selectedItems: IdentifiedArrayOf<Item>

        @BindingState var itemsSearchText = ""

        public init(items: IdentifiedArrayOf<Item> = [], selectedItems: IdentifiedArrayOf<Item> = []) {
            self.allItems = items
            self.selectedItems = selectedItems
        }

        func isItemSelected(_ item: Item) -> Bool {
            selectedItems.contains(where: { $0.id == item.id })
        }
        
        var isAllItemsSelected: Bool {
            selectedItems == allItems
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
            case publish(IdentifiedArrayOf<Item>)
        }
        
        case dismiss
        case setSelectedItem(Item)
        case selectAllItems
        case deselectAllItems
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
                if state.selectedItems.contains(item) {
                    state.selectedItems.remove(item)
                } else {
                    state.selectedItems.append(item)
                }
                return .none
                
            case .selectAllItems:
                state.selectedItems = state.items
                return .none

            case .deselectAllItems:
                state.selectedItems.removeAll()
                return .none

            case .doneButtonTapped:
                return .merge(
                    .send(.delegate(.publish(state.selectedItems))),
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

public struct MultiSelectionScreen<Item: SelectableItemProtocol>: View {
    let store: StoreOf<MultiSelectionFeature<Item>>

    public init(store: StoreOf<MultiSelectionFeature<Item>>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                GeometryReader { proxy in
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
                    .navigationTitle("Select Items")
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
                            .disabled(viewStore.selectedItems.count == 0 ? true : false)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        ZStack {
                            Rectangle()
                                .fill(Color.Semantic.tertiaryBackground)
                            
                            PrimaryButton(
                                title: viewStore.isAllItemsSelected ? L10n.General.deselectAll : L10n.General.selectAll,
                                action: {
                                    viewStore.send(viewStore.isAllItemsSelected ? .deselectAllItems : .selectAllItems)
                                }
                            )
                        }
                        .ignoresSafeArea()
                        .frame(width: proxy.size.width, height: 68)
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

struct MultiSelectionScreen_Preview: PreviewProvider {
    static var previews: some View {
        MultiSelectionScreen<User>(
            store: Store(
                initialState: MultiSelectionFeature<User>.State(
                    items: .init(uniqueElements: User.mock ?? [])
                ),
                reducer: {
                    MultiSelectionFeature()
                }
            )
        )
    }
}
