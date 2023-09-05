/*
Macros are generic functionality that should be stored in a common file and imported in.
*/
-- Date filter macro
{% macro date_filter(start_date, end_date, column_name) -%}
{% if start_date and end_date %}
    AND {{ column_name }} >= '{{ start_date }}'
    AND {{ column_name }} < '{{ end_date }}'
{% endif %}
{% endmacro %}

-- Text search macro
{% macro text_search_filter(search_term, fields) %}
  {% if search_term and fields -%}
  AND (
    {% for field in fields -%}
    ({{ field }}) ~* '.*{{ search_term }}.*'{% if not loop.last %} OR {% endif %}
    {%- endfor %}
  )
  {% endif %}
{% endmacro %}

-- Journey slug filtering
{% macro journey_slug_filter(slug_list) %}
  {% if slug_list and slug_list|length > 0 %}
  AND (
    {% for slug_term in slug_list %}
      journey_slug = '{{ slug_term }}'{% if not loop.last %} OR {% endif %}
    {% endfor %}
  )
  {% endif %}
{% endmacro %}

-- Filtering based on side
{% macro side_filter(req_side) %}
  {% if req_side %}
      {% if req_side == 'right' %}
        AND side = 'right'
      {% elif req_side == 'left' %}
        AND side = 'left'
      {% elif req_side == 'both' %}
        AND (side = 'left' OR side = 'right')
      {% endif %}
  {% endif %}
{% endmacro %}

/*
Report specific parameters should be set at the top of the specific report file.
*/

{% set date_filters = [
    ('invitation', 'invitation_date'),
    ('operation', 'operation_date'),
    ('registration', 'registration_date')
] %}

{% set text_search_filters = ['first_name', 'last_name', 'hospital_number'] %}

/*

This query, along with any other patient list query, will have two distinct stages.

1. Filtering - Based on what the specific patient list model contains, different front-end filtering options can be applied in the request body.
2. Sorting/Pagination - The request body will also include key parameters for page size, page number and fields to sort by.

Based on the logged in user, the report will query a dedicated view / table that will determine what patients the user can access.

*/

WITH visible_patients AS (

SELECT
  patient_journey_visibility_view.patient_journey_id
, patient_journey_visibility_view.patient_journey_prm_id
, patient_journey_visibility_view.patient_id
, patient_journey_visibility_view.patient_prm_id

FROM patient_journey_visibility_view

WHERE {{ request_persona_id }} = ANY(clinician_visibility)

)

, health_data AS (

SELECT
  fact_daily_health_data.patient_id
, SUM(fact_daily_health_data.value::INT) AS total_steps

FROM fact_daily_health_data
JOIN visible_patients ON fact_daily_health_data.patient_id = visible_patients.patient_id

GROUP BY
  fact_daily_health_data.patient_id

)

, filtering_patients AS (

SELECT

  rjah_patient_list.zone
, rjah_patient_list.first_name
, rjah_patient_list.last_name
, rjah_patient_list.global_patient_journey_id
, rjah_patient_list.patient_journey_id
, rjah_patient_list.patient_id
, rjah_patient_list.team_id
, rjah_patient_list.lead_id
, rjah_patient_list.journey_slug
, rjah_patient_list.procedure_code
, rjah_patient_list.procedure_label
, rjah_patient_list.side
, rjah_patient_list.is_test
, rjah_patient_list.is_active
, rjah_patient_list.hospital_number
, rjah_patient_list.sex
, rjah_patient_list.invitation_date
, rjah_patient_list.operation_date
, rjah_patient_list.registration_date
, rjah_patient_list.latest_pain_value
, rjah_patient_list.latest_pain_date
, rjah_patient_list.latest_mskhq_value
, rjah_patient_list.latest_mskhq_date
, rjah_patient_list.penultimate_mskhq_value
, rjah_patient_list.penultimate_mskhq_date
, rjah_patient_list.latest_eq5d5l_value
, rjah_patient_list.latest_eq5d5l_date
, rjah_patient_list.penultimate_eq5d5l_value
, rjah_patient_list.penultimate_eq5d5l_date
, mv_patient_journey_list_survey_status.num_activities_complete
, mv_patient_journey_list_survey_status.num_activities_incomplete
, mv_patient_journey_list_survey_status.num_days_to_next
, mv_patient_journey_list_survey_status.num_reviewable_surveys
, health_data.total_steps

FROM rjah_patient_list
JOIN visible_patients ON visible_patients.patient_journey_prm_id = rjah_patient_list.patient_journey_id
LEFT JOIN mv_patient_journey_list_survey_status ON visible_patients.patient_journey_id = mv_patient_journey_list_survey_status.patient_journey_id
LEFT JOIN health_data ON visible_patients.patient_id = health_data.patient_id

WHERE 1 = 1
-- Use text search macro and text search fields defined above
{% if inputs.filter.text_search -%}
  {{ text_search_filter(inputs.filter.text_search, text_search_filters) }}
{%- endif %}

-- Use journey slug filtering defined above
{% if inputs.filter.journey_slug -%}
  {{ journey_slug_filter(inputs.filter.journey_slug) }}
{%- endif %}

-- Use side filtering defined above
{% if inputs.filter.side -%}
  {{ side_filter(inputs.filter.side) }}
{%- endif %}

-- Use date filter macro and date filter tuples set defined above.
-- Supports having multiple date filter types in request body
-- SQL code will only be generated if the request body is accompanied by correct time bounding fields.
{% for filter, date_field in date_filters %}
    {% if inputs.filter[filter] and inputs.filter[filter].start_date and inputs.filter[filter].end_date %}
        {{ date_filter(inputs.filter[filter].start_date, inputs.filter[filter].end_date, date_field) }}
    {% endif %}
{% endfor %}
-- Existence check for key milestones
{% for filter, date_field in date_filters %}
    {% if inputs.filter[filter] and inputs.filter[filter].exists is defined %}
        {% if inputs.filter[filter].exists %}
            {{ 'AND ' + date_field + ' IS NOT NULL' }}
        {% else %}
            {{ 'AND ' + date_field + ' IS NULL' }}
        {% endif %}
    {% endif %}
{% endfor %}

)

SELECT
  filtering_patients.first_name
, filtering_patients.last_name
, filtering_patients.global_patient_journey_id
, filtering_patients.patient_journey_id
, filtering_patients.patient_id
, filtering_patients.team_id
, filtering_patients.lead_id
, filtering_patients.journey_slug
, filtering_patients.procedure_code
, filtering_patients.procedure_label
, filtering_patients.side
, filtering_patients.is_test
, filtering_patients.is_active
, filtering_patients.hospital_number
, filtering_patients.sex
, filtering_patients.invitation_date
, filtering_patients.operation_date
, filtering_patients.registration_date
, filtering_patients.latest_pain_value
, filtering_patients.latest_pain_date
, filtering_patients.latest_mskhq_value
, filtering_patients.latest_mskhq_date
, filtering_patients.penultimate_mskhq_value
, filtering_patients.penultimate_mskhq_date
, filtering_patients.latest_eq5d5l_value
, filtering_patients.latest_eq5d5l_date
, filtering_patients.penultimate_eq5d5l_value
, filtering_patients.penultimate_eq5d5l_date
, (SELECT COUNT(*) FROM filtering_patients) AS total_size
, num_activities_complete
, num_activities_incomplete
, num_days_to_next
, num_reviewable_surveys
, (SELECT SUM(num_reviewable_surveys) FROM filtering_patients) AS num_reviewable_surveys_total
, filtering_patients.total_steps

FROM filtering_patients

-- Enable sort by sort index (we want to use a named field instead, to be more explicit.)
-- Set a default ordering based on most recent invitation
{% if inputs.sort and (inputs.sort.parameter is defined and inputs.sort.desc is defined) -%}
ORDER BY {{inputs.sort.parameter}} {{'DESC NULLS LAST' if inputs.sort.desc else 'ASC NULLS FIRST'}}
{% else %}
ORDER BY invitation_date DESC NULLS LAST
{%- endif %}
-- Needs to be a 0-based index
{% if inputs.page and (inputs.page.size is defined and inputs.page.index is defined) -%}
OFFSET ({{inputs.page.index}} * {{inputs.page.size}}) LIMIT {{inputs.page.size}}
{% else %}
OFFSET (0 * 0) LIMIT 0
{%- endif %}
