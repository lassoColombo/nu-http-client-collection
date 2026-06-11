# Auto-generated client for Modules v8
# Source: https://raw.githubusercontent.com/zoho/crm-oas/main/v8.0/modules.json
# Auth: --token flag or $env.MODULES_TOKEN

const BASE_URL = "https://zohoapis.com/crm/v8"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MODULES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = ($name | url encode)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[($in.k | into string | url encode)]=($in.v | into string | url encode)" }) }
  if not $is_list { return [$"($n)=($value | into string | url encode)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
    "csv" => { let joined = ($value | each { $in | into string | url encode } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string | url encode } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string | url encode } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string | url encode } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=($v | into string | url encode)" } }
    _ => { $value | each {|v| $"($n)=($v | into string | url encode)" } }
  }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "put" => { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "patch" => { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url ($body | default {}) }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status == 204 { null } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else { $resp.body }
}

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://zohoapis.com/crm/v8" "https://zohoapis.eu/crm/v8" "https://zohoapis.in/crm/v8" "https://zohoapis.cn/crm/v8" "https://zohoapis.au/crm/v8"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def feature-name-completer [] { ["AI_CREDITS" "ASKZIA_MODULE_CREATION" "ASKZIA_WORKFLOW_CREATION" "AUTOMATIC_ANOMALY_ENCH_2" "BUSINESS_HOURS_SANDBOX" "Bundle_Product_Relations__s" "Bundles__s" "CANVAS_BP_MANDATORY_CSCRIPT" "CANVAS_FILES_UDSDOWNLOAD" "CANVAS_LV_CSCRIPT" "CANVAS_META_CACHE" "CANVAS_META_CACHE_REVERTER" "CANVAS_SERVICE" "CHATBOT_DETAIL_VIEW" "CHATBOT_MULTILINGUAL" "CHATBOT_NEW_UI_ENABLED" "CHATBOT_QUERY_SUGGESTION" "CHATBOT_V2_SPECIAL_ACCESS" "CLIENTPORTAL_FOOTER_HIDING" "CSCRIPT_ORG_ZAPPS_RETRY" "CSCRIPT_PAGES_MIGRATION" "CanvasRevisions" "Closure_Restrictions" "Competitors_Alert" "DATA_BRIDGE" "DT_Filter" "EXTERNAL_MODULE_CONFIG" "FORMULA_DYNAMIC_CRITERIA_LIMIT" "FX_CREDITS_STATIC_ISSUE_FIX" "FormviewCustomization" "IS_MAKING_NOTES_RT_NULL_ENABLED" "Kiosk" "Kiosk_Association_Limit_Per_Page" "Kiosk_Components" "Kiosk_Data_Hub" "Kiosk_Draft_Execution" "Kiosk_Execution_Per_User" "Kiosk_GetRecord_Selection_Limit" "Kiosk_GetRecord_Selection_Limit_Fetch" "Kiosk_GetRecords" "Kiosk_GetRecords_Fetch" "Kiosk_GetRecords_Fetch_limit" "Kiosk_Screen_Max_Buttons" "Kiosk_Screens" "Kiosk_Test_Run" "LZ_FAAS_TEST" "Lead_Status_Mapping" "ListviewCanvasRulesLimit" "ListviewCustomization" "ListviewFromImageToCanvas" "Lookup_Filter" "Lyte_Stage_Probability_Mapping" "MS_21VIANET" "MS_GRAPH_API" "Map_Dependency_Fields" "QuickML_Integration" "RELATED_LIST_FIELDS" "REPORT_FORMULA_DYNAMIC_CRITERIA_LIMIT" "REPORT_FORMULA_DYNAMIC_GROUP_LIMIT" "REPORT_FORMULA_DYNAMIC_SELECT_LIMIT" "SHIFT_IMPORT" "Stage_Probability_Mapping" "Stage_Total_Option_Count" "Stage_Used_Option_Count" "Translation_Workbench" "WF_BH_FLOW_CHANGE" "ZIA_DASHBOARD_COMPANION" "ZOHOCPQ" "ZRC" "Zoho_Docs" "abm" "abm_account" "abm_churn" "abm_contact" "abm_data_enrichment" "abm_deal" "abm_engagement_score" "abm_limit_enhancement" "abm_mood_score" "abm_plus" "abm_product" "abm_recommendation" "abm_recommendation_kakfa_disable" "abm_rel_flow_demo" "abm_segment_export" "abm_segment_journey_limit" "abm_suggested_segments" "abm_tour" "abm_voc" "abm_widget" "accessibility" "action_entities_product_configurator" "action_field_update_product_configurator" "activity_badge_upgrade" "activity_calendar" "add_meeting" "additional_pipelines" "address_field_enabled" "admin_center" "adwords" "analytics" "anomaly_notifications" "anomaly_notifications_new" "api_name_page_lyte" "api_trigger_limit" "apiname_page_corruption_view_enabled" "approval_processes" "appsspace_enabled" "assign_owner" "assignment_rules" "assignment_thresholds" "association_per_global_field" "audit_logs" "auto_responders" "auto_response_rules" "autofollowup_rules" "automation_new_massmail_sources_enabled" "bcc_dropbox" "best_mode_to_contact" "best_mode_to_contact_special_access" "best_time_analytics" "best_time_analytics_early_access" "best_time_analytics_segmentation_access" "best_time_analytics_special_access" "best_time_to_contact" "bigin_dashboards_enabled" "bigin_dashboards_enabled_trigger" "bigin_dashboards_new_signup" "bigin_domain_mapping" "blueprint_common_transitions" "blueprint_states" "blueprint_transition_during_fields" "blueprint_transitions" "blueprints" "bm_line_integration" "booking_event_participant_limit" "booking_pages" "bounce_email" "bounce_email_block" "bulk_write" "business_card" "business_hours" "business_messages" "c3" "cadences" "caldav" "calendar_booking" "calendar_schedule_team" "calendar_schedule_team_call" "calendar_schedule_team_event" "calendar_schedule_team_per_service" "calendar_schedule_user" "calendar_schedule_user_call" "calendar_schedule_user_event" "call_transcription" "call_transcription_early_access" "campaign_hierarchy_depth" "canvas_clickto_ajaxedit" "canvas_detailview_rl_scope" "canvas_flex_layout" "canvas_grid_layout" "canvas_reusable_component" "case_escalation_rules" "catalyst_solutions" "change_owner" "chart" "chart_view" "chat_support" "chatbot" "churn_prediction" "ciscoteams" "client_portal_saml_configuration" "cohort" "colourcode_option_count" "comparator" "compliance_settings" "component_suggestion" "component_suggestion_early_access" "connected_records" "connected_records_for_org_modules" "connected_workflows" "connected_workflows_limit" "consent_email" "copy_customization" "copy_customization_interdc" "cpq_dashboard_v2_2_support" "create_record" "criteria_entities_product_configurator" "crl_queries" "crl_queries_click" "crm_variables" "crm_widgets" "cscript" "cscript_commands" "cscript_dotsdk_new_flow" "cscript_dotsdk_spec_flow" "cscript_multiuserlookup_field" "cscript_mxn_field" "cscript_notes_events" "cscript_preload" "cscript_reports" "cscript_subform_events" "cscript_subform_feild_set_visible_function" "cscript_subform_row_lock_function" "cscript_support_in_portals" "cscript_uploadfields_events" "custom_ai_solutions" "custom_ai_studio" "custom_button" "custom_button_api_name_page_lyte" "custom_button_in_zia_widgets" "custom_dashboards" "custom_field" "custom_field_address_field" "custom_field_aggregate_fields" "custom_field_auto_number" "custom_field_cfpool_lookup" "custom_field_cfpool_userlookup" "custom_field_check_box" "custom_field_currency" "custom_field_dataparam" "custom_field_date" "custom_field_datetime" "custom_field_decimal" "custom_field_decision_box" "custom_field_email" "custom_field_fileupload" "custom_field_formula" "custom_field_imageupload" "custom_field_integer" "custom_field_large_text_area" "custom_field_long_integer" "custom_field_lookup" "custom_field_multi_select" "custom_field_multi_select_multi_module_lookup" "custom_field_multiuserlookup" "custom_field_mxn" "custom_field_percentage" "custom_field_phone" "custom_field_picklist" "custom_field_radio" "custom_field_radio_button" "custom_field_rich_text" "custom_field_small_text_area" "custom_field_text" "custom_field_text_area" "custom_field_url" "custom_field_userlookup" "custom_function_schedulers" "custom_function_upgrade" "custom_functions" "custom_link" "custom_link_new_tab" "custom_list_views" "custom_pages" "custom_related_list" "custom_reports" "customer_usage_data" "customization" "customize_setup" "custommodule" "customview_sandbox_support" "cv_anomaly" "dashboards_cache_reduced" "dashboards_enabled" "data_enrichment" "data_migration" "data_sharing" "data_sharing_rules" "data_sharing_rules_criteria" "data_storage" "data_storage_count" "data_storage_limits_more_than_200_user" "data_storage_per_user" "data_storage_per_user_more_than_200_user" "datahub" "date_queries" "deduplication_tool" "detailview_canvasfiles" "detailview_canvasrules" "detailview_customization" "detailview_queries_association" "di_cases_access" "di_cases_access_ee" "disable_composer_default_spellcheck" "disable_ecw_recipient" "disable_nio_flow" "disable_sandbox_emailconsumer" "domain_mappings" "dup_chk_preference" "duplicate_check_preference" "duplicate_image_detection" "duplicate_image_detection_special_access" "dxeditor_m1" "dynamic_groups_product_configurator" "dynamic_lookup_filter" "ear_for_email" "email" "emailConfigFeatures" "emailFeatures" "email_analytics" "email_attachments" "email_authentication" "email_authorisation" "email_credibility" "email_duplication" "email_emotion_analysis" "email_in" "email_insights" "email_intent_workflow" "email_notifications" "email_parser" "email_relay" "email_sending_restriction" "email_sharing" "email_storage" "email_storage_phase2" "email_storage_trigger_resync" "email_storage_ui" "email_templates" "email_templates_attachments_total_count" "email_templates_attachments_total_size" "email_workflow" "emailcatchAllFeatures" "emailparser" "emails_ai" "emailsai_selfmarketing" "emailsai_selfmarketing_phase2" "emailsai_summary_translation" "emailsai_test_account" "enable_record_state" "encrypt_field" "event_meeting_config" "event_participants_reminder" "event_rsvp_update" "events_notification_mail" "ews_mailapps_integ" "exchange" "excluded_fields" "excluded_profiles" "executable_file_upload_restrict" "export" "export_xlsx" "extensions" "external_field" "external_share_record" "facebook" "facebook_leadchain" "feedback_mechanism" "feeds_autofollowuprules_support" "feeds_followed_records_support" "field_encryption" "field_level_security" "field_prevent_duplicate" "field_updates" "file_cabinet" "file_storage_base" "file_storage_per_user" "firstname_limit_increase" "firstname_limit_increase_revert" "forecasts" "form_rules" "form_rules_actions" "form_rules_branch_condition" "form_rules_branch_criteria_per_condition" "form_rules_picklist_values_overall" "form_rules_picklist_values_per_condition" "form_rules_primary_condition" "free_data_backup" "full_data_sandbox" "functions" "functions_call_per_user" "functions_limits" "functions_minimum_calls" "funnel" "fx_mics" "gamification" "gdpr_lyte_revamp" "global_picklist_colourCode" "global_picklist_per_module" "global_picklists" "gmail" "gmail_rest_api" "google_calendar" "google_chat" "google_contacts" "google_docs" "google_instant_booking" "google_instant_booking_profile" "groups" "gsearch_auto_complete" "gsuite" "guided_selling" "hamburger_menu_recommended_section" "hide_unauthorized_create_link" "hipaa_compliance" "holidays" "homepage_components" "homepage_kiosk_components" "homepage_quick_link_components" "homepage_report_components" "homeview_customization" "imap" "import" "inc_used_option_count" "input_options_gs" "instant_sync_cvid" "integration_email" "intelligent_character_recognition" "intergration" "inventory_management" "inventory_templates" "journey_limit_increase" "kanban_view" "keyboard_shortcuts" "kiosk_versions_wise" "kpi" "large_global_set" "lead_chain" "lead_conversion_layoutrule" "leadchain" "leads_prediction" "linkedIn_sales_navigator" "linkedin" "linkedin_leadchain" "linking_module" "linkingmodule_custom_field" "linkingmodule_custom_field_check_box" "linkingmodule_custom_field_currency" "linkingmodule_custom_field_dataparam" "linkingmodule_custom_field_date" "linkingmodule_custom_field_datetime" "linkingmodule_custom_field_decimal" "linkingmodule_custom_field_decision_box" "linkingmodule_custom_field_email" "linkingmodule_custom_field_fileupload" "linkingmodule_custom_field_imageupload" "linkingmodule_custom_field_integer" "linkingmodule_custom_field_large_text_area" "linkingmodule_custom_field_long_integer" "linkingmodule_custom_field_lookup" "linkingmodule_custom_field_multi_select" "linkingmodule_custom_field_percentage" "linkingmodule_custom_field_phone" "linkingmodule_custom_field_pick_list" "linkingmodule_custom_field_radio" "linkingmodule_custom_field_radiobutton" "linkingmodule_custom_field_rich_text" "linkingmodule_custom_field_small_text_area" "linkingmodule_custom_field_text" "linkingmodule_custom_field_text_area" "linkingmodule_custom_field_url" "listview_queries_association" "live_chat" "locking_rules" "lookup_filter_new_mapping" "lux" "m360_newmail_queue" "macro" "macros_suggest" "mail_apps" "mail_merge" "mailbox_mails_population" "mailchimp" "mailcollabview" "mailmerge_email" "manage_signals" "mapview_and_autosuggest" "marketing_attribution" "marketplace" "mass_convert" "mass_delete" "mass_email" "mass_transfer" "mass_update" "mass_update_by_cvid" "massconvert_dealcreation_newflow" "mb_delete_limit_popup" "mb_lyte_qc_enabled" "mb_new_header" "microsoft_office" "microsoft_outlook" "microsoft_teams" "mobile_apps" "mobilecanvas_kiosk_support" "mobilecanvas_navigator" "mobiledetailview_customization" "module_builder_new_ui" "module_deleted_core_flow" "module_limit_per_process" "module_summary" "modules_prediction" "ms_calendar" "multi_page_layout" "multicurrency" "multicurrency_nf" "multipipelines" "multiple_kanban_view" "multiselect_filter_options" "nbx_early_access" "nbx_goal" "nbx_goal_ui" "nbx_live_update" "next_best_action" "nextgenui_enabled" "nextgenui_new_panel_enabled" "nextgenui_setuphome_enabled" "nextgenui_user_settings_preference" "notes_badge_listview" "notes_edit_delete_by_owner" "notes_rich_text_support" "notes_rich_text_support_disable" "notes_short_content" "notify_owner" "office365" "orchestration_actions" "orchestration_execution_limit" "orchestration_versions_wise" "organization_emails" "organize_tabs" "outlook" "page_layout" "pages" "participants_limit" "path_finder" "path_finder_version_wise" "pathfinder_instance_creation_limit" "pathfinder_limit_increase" "pathfinder_processing_count" "payments_integration" "pdf_sendmail_to_contacts" "people_enrichment" "people_enrichment_extension_migration" "people_enrichment_isc" "personal_health_fields" "phonebridge" "picklist colour coding" "picklist colour coding V2" "picklist_history_tracking" "pitch" "pop_up_reminders" "portal_authorizationmodule" "portal_parentmodule" "portal_personalitymodule" "portal_readonlymodule" "portal_user_group_new_ui" "portal_user_list_page_landing" "portal_users" "portal_users_new" "portal_users_store_widget" "portals" "portals_authorization_criteria_count" "portals_signup_form" "prediction" "prediction_analytics" "presentation" "presentation_dc" "presentation_early_access" "presentation_special_access" "price_rule" "price_rule_direct" "price_rule_range" "price_rule_volume" "printview_customization" "privacy_modules" "private_fields" "prm_feature_enabled" "product_configurator" "production_tracking" "profiles" "public_field" "quadrant" "query_associations" "query_sources" "query_workbench" "question_pages_gs" "recommendation" "recommendation_early_access" "recommendation_early_access_new_dc" "recommendation_for_workflow" "record_clone" "record_image" "record_level_sharing" "record_level_sharing_groups" "record_level_sharing_indirect_groups" "record_level_sharing_indirect_roles" "record_level_sharing_indirect_users" "record_level_sharing_roles" "record_level_sharing_users" "record_locking_configurations" "record_state_options_limit" "record_tags_count" "records_limit" "records_limit_custom_view" "related_list_customization" "relay_smtp_debug" "reminders" "remote_sales_office" "rename_tabs" "report_aggregates_limit" "report_export_daily" "report_export_records_limit" "reporting_hierarchy" "reports" "reports_scheduled" "restricted_custom_buttons" "revert_connected_records" "review_process" "rfm_draft" "rfm_record_processing_count" "rfm_segmentation" "rfm_segmentation_contribution_module" "roles" "route_iq" "rules_limit_per_module" "sales_motivator" "sales_motivator_dashboards" "sales_motivator_dashboards_comp" "sales_motivator_games" "sales_motivator_games_rules" "sales_motivator_games_teams" "sales_motivator_games_users" "sales_motivator_rules" "sales_motivator_targets" "sales_motivator_teams" "sales_motivator_teams_users" "sales_motivator_tvchannels" "sales_motivator_tvchannels_comp" "sales_signals" "sales_signals_mobile_notification_support" "salesinbox" "salesinbox_mobile" "sample_feature_1" "sample_subfeature_1" "sandbox" "sandbox_data_population_modules" "sandbox_email_support" "sandbox_partial_deployment" "schedule_call" "schedule_mail" "schedule_mass_operation" "schedule_reports" "scheduled_mass_email" "schedules" "scoring_rules" "search_layout" "send_mail" "send_mail_attachments_total_count" "send_mail_attachments_total_size" "send_mail_inventory_module" "sentiment_analysis" "services" "shift_hours" "similarity" "similarity_early_access" "sky_eye" "slack" "smart_filters_limit" "smart_prompt" "smart_prompt_anthropic_llm" "smart_prompt_anthropic_llm_special_access" "smart_prompt_cohere_llm" "smart_prompt_cohere_llm_special_access" "smart_prompt_deepseek_llm" "smart_prompt_deepseek_llm_special_access" "smart_prompt_googleai_llm" "smart_prompt_googleai_llm_special_access" "smart_prompt_in_cb" "smart_prompt_in_cb_special_access" "smart_prompt_new_bot" "smart_prompt_new_bot_v2" "smart_prompt_new_bot_v2_special_access" "smart_prompt_siliconflow_llm" "smart_prompt_siliconflow_llm_special_access" "smart_prompt_special_access" "smart_prompt_zia_llm" "smart_prompt_zia_llm_special_access" "social" "split_view_enabled" "stage" "static_resource" "static_subform_max_rows" "store_widget" "subForm_configured_fields" "subform" "subform_allowed_file_limit" "subform_bulk_addition_max_rows" "subform_custom_field" "subform_custom_field_check_box" "subform_custom_field_large_text_area" "subform_custom_field_pick_list" "subform_custom_field_small_text_area" "subform_custom_field_text_area" "subform_encrypt_field" "subform_max_rows_crud" "subform_max_rows_crud_v2" "subform_module_max_rows_crud" "subform_module_max_rows_crud_v2" "subform_multiple_fileupload" "subform_permissions" "subform_permissions_disable" "subform_v2" "subject_line_suggestion" "support_access" "switch_edition" "system_address_field_enabled" "tab_groups" "tags" "talk_with_us_zoho_voice_call" "target_meter" "tasks" "team_module_enabled" "team_module_requester_settings" "team_module_requester_settings_disable" "team_spaces" "teamdrive" "teammodule" "teammodule_custom_field" "teamspace_enabled" "telephony" "territory_management" "text_call_intelligence" "text_case_intelligence" "text_email_intelligence" "text_meeting_intelligence" "text_note_intelligence" "text_product_intelligence" "tiktok_leadchain" "total_data_sharing_rules" "total_validation_rules" "trend_analysis" "trends" "triggers" "twitter" "unique_chk_for_contacts" "unique_field" "unsubscribe" "unused_option_count" "used_option_count" "user_associations" "user_associations_admin_users" "user_associations_module_users" "user_licenses" "user_type" "validation_rule_branch_condition" "validation_rule_custom_function" "validation_rule_primary_condition" "validation_rules" "visitor_tracking" "voc" "voc_anonymous" "voc_component_limit" "voc_computation_keyword_limit" "voc_dashboard_limit" "voc_for_loweredition" "voc_inventory" "voc_parent" "voc_primary" "voc_sales" "waterfall" "web_apps" "web_case" "web_contact" "web_custommodule" "web_forms" "web_lead" "web_multimodule_fields" "web_tabs" "web_vendor" "webform analytics cleanup duration" "webform_abtesting" "webform_analytics" "webform_analytics_revamp" "webform_analytics_url_revamp" "webform_fields_limit" "webform_multidomain" "webform_suggestions" "webhooks" "wf_di_notification" "wizard_cross_screen_fields_in_criteria" "wizard_cscript_transition_begin" "wizards" "workflow" "workflow_report" "workflow_rules" "workflow_rules_executeon_datetime" "workflow_rules_executeon_delete" "workflow_rules_executeon_delete_plugin" "workflow_rules_executeon_fieldupdate" "workflow_rules_executeon_safieldupdate" "workflow_rules_executeon_sectionupdate" "workflow_rules_summary" "workflow_suggestion" "workflow_time_based_actions" "writing_assistant" "writing_assistant_special_access" "zcircuits_free_execution_per_month" "zcircuits_free_execution_per_user" "zcircuits_max_execution_per_month" "zia" "zia_agent" "zia_agent_in_cb" "zia_anomaly" "zia_call_analytics" "zia_call_analytics_automation" "zia_call_audio_transcription" "zia_call_transcription_cops" "zia_config" "zia_conversation_summary" "zia_conversation_summary_special_access" "zia_copilot" "zia_copilot_language_support" "zia_field_creation" "zia_in_email" "zia_owner_recommendation" "zia_pitch_special_access" "zia_record_summary" "zia_record_summary_special_access" "zia_reminder" "zia_sales_recommendation" "zia_score" "zia_score_automation" "zia_score_special_access" "zia_scoring_rule" "zia_scoring_rule_special_access" "zia_summary" "zia_summary_multilanguage_support" "zia_summary_multilanguage_support_special_access" "zia_summary_special_access" "zia_supported_deployment" "zia_vision" "zia_voice" "zoho_assist" "zoho_backstage" "zoho_bookings" "zoho_campaigns" "zoho_campaigns_create" "zoho_circuits" "zoho_circuits_execution" "zoho_circuits_pricing" "zoho_cliq" "zoho_contracts" "zoho_creator" "zoho_docs" "zoho_expense" "zoho_flow" "zoho_flow_pricing" "zoho_forms" "zoho_fsm" "zoho_invoice" "zoho_lens" "zoho_mail" "zoho_mobile_edition" "zoho_pagesense" "zoho_projects" "zoho_reports" "zoho_sheet" "zoho_showtime" "zoho_sign" "zoho_subscription" "zoho_support" "zoho_survey" "zoho_webinar" "zone"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "settings-modules list" } } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name not-in [$mod_name "commands"] | get decl_id)
  scope commands | where decl_id in $cmd_ids | each {|cmd|
    let sig = $cmd.signatures | values | first
    let params = $sig
      | where parameter_type not-in ["input" "output"]
      | where parameter_name not-in $builtin_flags
      | select parameter_name parameter_type syntax_shape is_optional description
    let return_type = ($sig | where parameter_type == "output" | get -o syntax_shape | first | default "any")
    {
      name: ($cmd.name | str replace $"($mod_name) " "")
      description: $cmd.description
      extra_description: $cmd.extra_description
      return_type: $return_type
      params: $params
    }
  }
}

# Retrieve CRM module metadata
#
# GET /settings/modules
# operationId: getModules
export def "settings-modules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # Filter modules by their visibility status. Accepts comma-separated values to retrieve modules matching any of the specified statuses. Case-sensitive.
  --feature-name: string@feature-name-completer # Filter modules by feature name. Retrieves modules associated with the specified feature. Case-sensitive, follows snake_case format. Empty string returns 400 error.
  --include: string # Comma-separated list of additional fields to include in the response. Allows retrieving optional module metadata that is not returned by default.
]: nothing -> record<modules: table<global_search_supported: bool, public_fields_configured: bool, recycle_bin_on_delete: bool, has_more_profiles: bool, sub_menu_available: bool, lookupable: bool, profile_count: int, module_type: string, cc_enabled: bool, deletable: bool, description: string, creatable: bool, inventory_template_supported: bool, modified_time: string, presence_sub_menu: bool, triggers_supported: bool, id: string, api_name: string, plural_label: string, actual_plural_label: string, actual_singular_label: string, singular_label: string, isBlueprintSupported: bool, visibility: int, convertable: bool, editable: bool, emailTemplate_support: bool, email_parser_supported: bool, filter_supported: bool, show_as_tab: bool, web_link: string, viewable: bool, api_supported: bool, quick_create: bool, generated_type: string, static_subform_properties: record, feeds_required: bool, scoring_supported: bool, webform_supported: bool, arguments: list, module_name: string, business_card_field_limit: int, access_type: string, private_profile: record, track_current_data: bool, modified_by: any, profiles: list, parent_module: record, status: string, sequence_number: int, territory: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "feature_name" $feature_name "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/settings/modules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom CRM module
#
# POST /settings/modules
# operationId: createModules
# --modules item shape: {singular_label: string, plural_label: string, api_name: string, profiles: list, display_field?: record}
export def "settings-modules createModules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --modules: list # Array containing a single module definition to create. Only one module can be created per request. — item shape: {singular_label: string, plural_label: string, api_name: string, profiles: list, display_field?: record}
]: any -> record<modules: table<code: string, details: record, message: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/modules")
  let body = {modules: $modules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update CRM modules
#
# PUT /settings/modules
# operationId: updateModules
# --modules item shape: {singular_label?: string, plural_label?: string, id: string, profiles?: list}
export def "settings-modules updateModules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --modules: list # Array of modules to update. Supports batch updates with multiple modules in a single request. Each module must have a unique ID within the request. — item shape: {singular_label?: string, plural_label?: string, id: string, profiles?: list}
]: any -> record<modules: table<code: string, details: record, message: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/settings/modules")
  let body = {modules: $modules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get module metadata by API name
#
# GET /settings/modules/{moduleIdentifier}
# operationId: getModuleByApiName
export def "settings-modules get" [
  moduleIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<modules: table<global_search_supported: bool, public_fields_configured: bool, recycle_bin_on_delete: bool, has_more_profiles: bool, sub_menu_available: bool, lookupable: bool, profile_count: int, module_type: string, cc_enabled: bool, deletable: bool, description: string, source: string, creatable: bool, inventory_template_supported: bool, modified_time: string, presence_sub_menu: bool, triggers_supported: bool, id: string, api_name: string, plural_label: string, actual_plural_label: string, actual_singular_label: string, singular_label: string, isBlueprintSupported: bool, visibility: int, convertable: bool, editable: bool, emailTemplate_support: bool, email_parser_supported: bool, filter_supported: bool, show_as_tab: bool, web_link: string, viewable: bool, api_supported: bool, quick_create: bool, generated_type: string, static_subform_properties: record, feeds_required: bool, scoring_supported: bool, webform_supported: bool, arguments: list, module_name: string, business_card_field_limit: int, access_type: string, private_profile: record, track_current_data: bool, modified_by: any, profiles: list, parent_module: record, _field_states: list, business_card_fields: list, per_page: int, _properties: list, _on_demand_properties: list, search_layout_fields: list, kanban_view_supported: bool, lookup_field_properties: record, kanban_view: bool, chart_view: bool, chart_view_supported: bool, related_lists: list, filter_status: bool, related_list_properties: record, display_field: any, layouts: list, fields: list, custom_view: record, zia_view: bool, default_mapping_fields: list, activity_badge: string, status: string, sequence_number: int, _others_awaiting: bool, territory: record, showleadchainsync: bool, show_social: bool, show_visitor: bool, show_googlesync: bool, showtiktoksync: bool, show_webform: bool, showfacebooksync: bool, show_emailparser: bool, showlinkedinsync: bool, masked_fields_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settings/modules/($moduleIdentifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update module labels and profiles
#
# PUT /settings/modules/{moduleIdentifier}
# operationId: updateModuleByApiName
# --modules item shape: {singular_label: string, plural_label: string, id: string, profiles: list}
export def "settings-modules updateModuleByApiName" [
  moduleIdentifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  modules: list # Array containing a single module object to update. — item shape: {singular_label: string, plural_label: string, id: string, profiles: list}
]: any -> record<modules: table<code: string, details: record, message: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/settings/modules/($moduleIdentifier)")
  let body = {modules: $modules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
