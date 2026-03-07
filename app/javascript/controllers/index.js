// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application"

import CountdownController from "./countdown_controller"
import MatchAccordionController from "./match_accordion_controller"
import SortTableController from "./sort_table_controller"
import DraftFilterController from "./draft_filter_controller"
import TabFilterController from "./tab_filter_controller"
import MobileNavController from "./mobile_nav_controller"

application.register("countdown", CountdownController)
application.register("match-accordion", MatchAccordionController)
application.register("sort-table", SortTableController)
application.register("draft-filter", DraftFilterController)
application.register("tab-filter", TabFilterController)
application.register("mobile-nav", MobileNavController)
