// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"

import CountdownController from "controllers/countdown_controller"
import MatchAccordionController from "controllers/match_accordion_controller"
import SortTableController from "controllers/sort_table_controller"
import DraftFilterController from "controllers/draft_filter_controller"
import TabFilterController from "controllers/tab_filter_controller"
import MobileNavController from "controllers/mobile_nav_controller"

application.register("countdown", CountdownController)
application.register("match-accordion", MatchAccordionController)
application.register("sort-table", SortTableController)
application.register("draft-filter", DraftFilterController)
application.register("tab-filter", TabFilterController)
application.register("mobile-nav", MobileNavController)
