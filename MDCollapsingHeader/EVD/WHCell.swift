//
//  WHCell.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 2/9/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

import UIKit

// TODO: - Break apart `WHCell` enum the same way `WHVC` or `CZK` enums are broken apart and organized. Ideally each of the comments separating groups of `WHCell` groups should be its own parent enum taking all the related cases with it.

/// A Predictable and organized constants tool for setting up cells
enum WHCell: String, CellEnumable {
    case
        // Sports Tab (Main page on home screen)
//        homePageCell, promoCarousel, promoCarouselEmpty, promoList,
//
//        // Top Nav Cells
//        topNavCell, topNavLiveCell, topNavAllSportsCell,
//
//        // Search Tab Cells
//        suggestionCell, recentSearchesHeader,

        // Magic Six Pack Cells
        mspDateHeader, mspSixPack, mspLoading, mspSixPackTableCell,
//        mspMRHeader, mspMRMarket, mspMRPack, mspMRBottom, mspMRShowAll, // MSP Multi-Row Cells
    
        // All Sports Cell a.k.a AZ Sports
//        sportsCell, competitionCell, searchResultsCell,

        // Event Details Cells
        evdSelectionCell, evdShowAllCell, evdAltSpreadCell, evdSectionCell, evdTabsGroupingCell, evdCompactCell,

        // Futures Cells
//        futuresSectionHeader, futuresMarketTitle, futuresPack, futuresShowAllButton, futuresBottomSpacer,
//
//        // My Bet Cells
//        betCell, betsCashoutCell,
//
//        // Parlay
//        betParlayParent, betParlayLeg,
//
//        // Filter
        filterViewCell//, filterViewCellMultiSelect,
//
//        // Multi Select Filter PopUp cell with on/off switch options
//        filterPopUpToggleCell, filterPopUpCustomDateCell,
//
//        // Upload Documents CollectionView
//        documentCollectionViewCell, addNewCollectionViewCell, uploadCollectionViewCell,
//
//        // Upload Documents TableView
//        documentCell, uploadDocumentsTextCell, documentsCell,
//        uploadDocumentsDescriptionCell, uploadDocumentsSubmitCell, documentsListCell,
//
//        // Responsible Gaming History
//        responsibleGamingHistoryCell,
//
//        // Account
//        accountHeaderCell, accountVerifiedHeaderCell, accountUnverifiedHeaderCell, accountMainCell, accountLogoutCell, accountRegulatoryCell,
//
//        // Pending Prizes
//        taxReportedPrizeCell,
//
//        // Transactions History
//        transactionCell,
//
//        // Casino Tab
//        casinoLobbyContainer, casinoGamesCollectionContainer, casinoUserPreferencesContainer, casinoGameIcon, casinoGameDetail, casinoEmptyCollection, casinoNavCell,
//
//        liveGamesCarousel,
//
//        // Bonus Activity
//        bonusActivityCell, bonusActivityPlaceholderCell, bonusRemoveCell,
//
//        // Bonus Offers
//        bonusOffersCell,
//
//        // Caesars Rewards
//        caesarsCardCell, caesarsMainCell, caesarsFooterCell,
//
//        // Help Modal
//        helpSection, helpCell,
//
//        boostsCell,
//
//        // State Selection
//        stateSelectorListCell,
//
//        // Self-Exclusion
//        progressViewHeader, textCell, plainTextCell, twoButtonCell, agreeableTextCell, regularTextField, periodTextField, selfExclFooter,
//
//        // Launch
//        launchStateSelectorCell, launchStateSelectorHeaderCell

    var type: UIView.Type {
        switch self {

//        case .homePageCell:                     return HomePageTableViewCell.self
//        case .topNavCell:                       return TopNavCollectionCell.self
//        case .topNavLiveCell:                   return TopNavLiveCollectionCell.self
//        case .topNavAllSportsCell:              return TopNavAllSportsCollectionCell.self
//        case .promoCarousel:                    return PromotionsCell.self
//        case .promoCarouselEmpty:               return PromotionsCarouselEmptyCell.self
//        case .promoList:                        return PromotionsListTableCell.self
//        case .suggestionCell:                   return SuggestionCell.self
//        case .recentSearchesHeader:             return RecentSearchesHeader.self

        // MagicSixPack Cells
//        case .mspDateHeader:                    return ReusableSectionHeaderCell.self
        case .mspSixPack:                       return MagicSixPackCell.self
        case .mspSixPackTableCell:              return MSPTableViewCell.self
//        case .mspLoading:                       return MSPLoadingCell.self
        
        // MSP Multi-Row Cells
//        case .mspMRHeader:                      return MSPMultiRowHeaderCell.self
//        case .mspMRMarket:                      return MSPMultiRowMarketCell.self
//        case .mspMRPack:                        return MSPMultiRowPackCell.self
//        case .mspMRBottom:                      return MSPMultiRowBottomCell.self
//        case .mspMRShowAll:                     return MSPMultiRowShowAllCell.self

        case .evdSelectionCell:                 return EventDetailMarketSelectionCell.self
        case .evdShowAllCell:                   return EventDetailsShowAllCell.self
        case .evdAltSpreadCell:                 return EVDAltSpreadCell.self
        case .evdSectionCell:                   return EVDSectionCell.self
        case .evdTabsGroupingCell:              return EVDTabsGroupingCell.self
        case .evdCompactCell:                   return EVDCompactMarketCell.self
            
//        case .futuresSectionHeader:             return FuturesSectionHeaderCell.self
//        case .futuresMarketTitle:               return FuturesMarketTitleCell.self
//        case .futuresPack:                      return FuturesPackCell.self
//        case .futuresShowAllButton:             return FuturesShowAllButtonCell.self
//        case .futuresBottomSpacer:              return FuturesBottomSpacerCell.self
//
//        case .betCell:                          return BetCell.self
//        case .betsCashoutCell:                  return BetsCashoutCell.self
//        case .betParlayParent:                  return BetParlayParentCell.self
//        case .betParlayLeg:                     return BetParlayLegCell.self
//
        case .filterViewCell:                   return FilterDataCell.self
//        case .filterViewCellMultiSelect:        return FilterDataCellMultiSelect.self
//        case .filterPopUpToggleCell:            return FilterPopUpToggleCell.self
//        case .filterPopUpCustomDateCell:        return FilterPopUpCustomDateCell.self
//
//        case .documentCollectionViewCell:       return DocumentCollectionViewCell.self
//        case .addNewCollectionViewCell:         return AddNewCollectionViewCell.self
//        case .uploadCollectionViewCell:         return UploadCollectionViewCell.self
//
//        case .documentCell:                     return DocumentTableViewCell.self
//        case .uploadDocumentsTextCell:          return UploadDocumentsTextTableViewCell.self
//        case .documentsCell:                    return DocumentsCollectionViewTableViewCell.self
//        case .uploadDocumentsDescriptionCell:   return UploadDocumentsDescriptionTableViewCell.self
//        case .uploadDocumentsSubmitCell:        return UploadDocumentsSubmitTableViewCell.self
//        case .documentsListCell:                return DocumentsListTableViewCell.self
//
//        case .responsibleGamingHistoryCell:     return ResponsibleGamingHistoryTableViewCell.self
//
//        case .accountHeaderCell:                return AccountHeaderCell.self
//        case .accountVerifiedHeaderCell:        return AccountVerifiedHeaderCell.self
//        case .accountUnverifiedHeaderCell:      return AccountUnverifiedHeaderCell.self
//        case .accountMainCell:                  return AccountMainCell.self
//        case .accountLogoutCell:                return AccountLogoutCell.self
//        case .accountRegulatoryCell:            return AccountRegulatoryCell.self
//
//        case .taxReportedPrizeCell:             return TaxReportedPrizeTableViewCell.self
//
//        case .transactionCell:                  return TransactionTableViewCell.self
//
//        case .casinoLobbyContainer:             return CasinoLobbyContainerCell.self
//        case .casinoGamesCollectionContainer:   return CasinoGamesCollectionContainerCell.self
//        case .casinoUserPreferencesContainer:   return CasinoUserPreferencesContainerCell.self
//        case .casinoGameIcon:                   return CasinoGameIconCollectionCell.self
//        case .casinoGameDetail:                 return CasinoGameDetailCollectionCell.self
//        case .casinoEmptyCollection:            return CasinoEmptyTableViewCell.self
//        case .casinoNavCell:                    return CasinoNavigationViewCell.self
//
//        case .liveGamesCarousel:                return LiveGamesCarouselCell.self
//
//        case .bonusActivityCell:                return BonusActivityTableViewCell.self
//        case .bonusActivityPlaceholderCell:     return BonusActivityPlaceholderCell.self
//        case .bonusRemoveCell:                  return BonusRemoveCell.self
//
//        case .bonusOffersCell:                  return BonusOffersTableViewCell.self
//
//        case .caesarsCardCell:                  return CaesarRewardsCardCell.self
//        case .caesarsMainCell:                  return CaesarRewardsMainCell.self
//        case .caesarsFooterCell:                return CaesarRewardsFooterCell.self
//        case .sportsCell:                       return SportsCell.self
//        case .competitionCell:                  return SportsCompetitionCell.self
//        case .searchResultsCell:                return SearchResultsCell.self
//
//        case .helpSection:                      return HelpSectionHeader.self
//        case .helpCell:                         return HelpTableViewCell.self
//        case .boostsCell:                       return BoostsCell.self
//
//        case .stateSelectorListCell:            return StateSelectorListCell.self
//        case .launchStateSelectorCell:          return LaunchStateSelectorCell.self
//        case .launchStateSelectorHeaderCell:    return LaunchStateSelectorHeaderCell.self
//
//        case .progressViewHeader:               return SelfExclProgressHeader.self
//        case .textCell:                         return SelfExclTextCell.self
//        case .plainTextCell:                    return SelfExclPlainTextCell.self
//        case .twoButtonCell:                    return SelfExclTwoButtonsCell.self
//        case .agreeableTextCell:                return SelfExclAgreeableTextCell.self
//        case .selfExclFooter:                   return SelfExclFooter.self
//        case .periodTextField:                  return SelfExclPickerTFCell.self
//        case .regularTextField:                 return SelfExclTextField.self
        default: fatalError()
        }
    }

    /// Default height values for Cells/Layouts
    var defaultCellHeight: CGFloat {
        switch self {
//        case .homePageCell:                 return 330.0
//        case .topNavCell:                   return 80.0
//        case .promoCarousel:                return 120.0
//        case .promoCarouselEmpty:           return 45.0

        case .mspDateHeader:                return 44.0
        case .mspSixPack:                   return 120.0
        case .mspSixPackTableCell:          return 70.0
        case .mspLoading:                   return 100.0

//        case .futuresSectionHeader:         return 69.0
//        case .futuresMarketTitle:           return 30.0
//        case .futuresShowAllButton:         return 59.0
//        case .futuresBottomSpacer:          return 32.0
//        case .futuresPack:                  return 54.0
//
//        case .betCell:                      return 165.0
//        case .betsCashoutCell:              return 140.0
//        case .betParlayParent:              return 95.0
//        case .betParlayLeg:                 return 120.0
        case .filterViewCell:               return 34.0
//        case .filterViewCellMultiSelect:    return 34.0
//        case .filterPopUpToggleCell:        return 64.0
//        case .filterPopUpCustomDateCell:    return 130.0
//        case .accountMainCell:              return 84.0
//        case .liveGamesCarousel:            return 88.0
//        case .bonusActivityCell:            return 280.0
//        case .bonusOffersCell:              return 202.0
//        case .caesarsCardCell:              return 385.0
//        case .caesarsMainCell:              return 84.0
//        case .caesarsFooterCell:            return 150.0
//        case .helpCell:                     return 52.0
//        case .helpSection:                  return 56.0
//        case .boostsCell:                   return 194.0
//        case .stateSelectorListCell:        return 64.0
//        case .launchStateSelectorCell:      return 70.0
//        case .searchResultsCell:            return 65.0
        default: return 0.0
        }
    }
}

//
//  WHCell+CellAssistantProtocols.swift
//  WH_CZR_SBK
//
//  Created by Michael Dimore on 3/5/21.
//  Copyright © 2021 Caesar's Entertainment. All rights reserved.
//

/// Cell helper protocols for faciliting Cell configuration in WHCell.
protocol CellEnumable: CellAssistant {
    var reuseId: String { get }
    var nib: UINib { get }
    var type: UIView.Type { get }
}

extension CellEnumable {
    var reuseId: String { String(describing: type) }
    var nib: UINib { UINib(nibName: reuseId, bundle: nil) }
}

protocol CellAssistant {
    var defaultCellHeight: CGFloat { get }
    var defaultLayoutSize: NSCollectionLayoutSize { get }
    func defaultCellSize(_ width: CGFloat) -> CGSize
}

extension CellAssistant {
    // Full screen width, and `defaultCellHeight`
    func defaultCellSize(_ width: CGFloat) -> CGSize { .init(width: width, height: defaultCellHeight) }

    // Full screen width (Fractional width 1.0), and estimated numeric height using `defaultCellHeight`
    var defaultLayoutSize: NSCollectionLayoutSize { itemSize(defaultCellHeight) }

    private func itemSize(_ heightEst: CGFloat) -> NSCollectionLayoutSize {
        NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(heightEst))
    }
}
