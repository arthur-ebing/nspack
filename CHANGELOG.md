# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres roughly to [Semantic Versioning](http://semver.org/).


## [Unreleased]
### Added
- Gossamer data dashboard
- Multi-pallet moves
- Packing specs can set a default label template
- Ability to force the shipped date on loads
### Changed
- Pallets added to a previously shipped load get the new shipped date on ship event - even though the load's shipped at does not change.
### Fixed

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
