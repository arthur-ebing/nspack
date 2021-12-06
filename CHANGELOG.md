# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres roughly to [Semantic Versioning](http://semver.org/).


## [Unreleased]
### Added
### Changed
### Fixed

## [1.0.4] - 2021-12-06
### Added
- EDI in process: added manual intake flow to create a PO in without a file.
- Tripsheet logs.
- Provision and configure NTD devices from system resources grid.
- Empty bin reports for tracking empty bin assets.
### Changed
- Rename `Active` setups/packspecs to `Available` setups/packspecs.
- 9-digit pallet numbers - accept `23` as a valid prefix.
- Presort integration events handled by singleton Que jobs.
- Various changes to PPECB inspection related to failed state.
- Single bin edit - edit legacy data attributes too.
### Fixed
- Pallets table - index on `load_id`.
- Cloning pallets - retain the `depot_pallet` flag's value.
- Standard cartons calculation.
- Prevent run execution if any allocated label template is inactive.

## [1.0.3] - 2021-11-18
### Added
- Changes for Kromco go-live (Presort, staging runs, MAF integration, HW integration, RMT legacy data
- Pallet weights can use derived masterfile weights
- Bin asset control
- FG Orders
- Beep sound in RMD forms when validation etc fails
- RMF forms can be submitted automatically once a set of inputs have all received values
- CA treatment locations - set status of location and bins in location
- Move stock service
- Depot pallet buildups
- Lock pallets via WIP status
- Reporting industry setting "apples"
- Reprint carton labels from a sequence/pallet when pallet has individual cartons
### Changed
- Dataminer admin menu options moved to a separate `Manage` program.
- RMD forms emit a beep when errors occur.

## [1.0.2] - 2021-10-05
### Added
- LI in EDI process
- Presort bin staging
- Work orders
### Changed
- Stock pallets for loads grids optimised
### Fixed
- Rework of cultivar for production run: allow current cultivar to apply to early cartons/pallets that differ.

## [1.0.1] - 2021-10-04
### Added
- Gossamer data dashboard
- Multi-pallet moves
- Packing specs can set a default label template
- Ability to force the shipped date on loads
### Changed
- Pallets added to a previously shipped load get the new shipped date on ship event - even though the load's shipped at does not change.

## [1.0.0] - 2021-08-31
### Added
- Titan addendum process
- Sales Orders
- Scan legacy cartons
- Scrap pallet in reworks checks
- Scrap and unscrap cartons
- Fruit industry levies for customers
- Colour percentages
### Changed
- Dataminer grids now share standard javascript grid logic
- Packing spec code changed to allow for blank cultivar
- Pallet buildup can auto-create a pallet
- Re-wrote stock pallets query to make grids load faster
### Fixed
- Farm/PUC/Orgs uniqueness fixed
- Run is re-executed after reworks for run-related data (like orchard)

## [0.1.1] - 2019-06-21
### Added
- Production region CRUD
- RMT class CRUD
- Season group CRUD
- RMT delivery destintation CRUD
