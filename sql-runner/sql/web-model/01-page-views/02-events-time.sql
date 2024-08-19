-- Copyright (c) 2016 Snowplow Analytics Ltd. All rights reserved.
--
-- This program is licensed to you under the Apache License Version 2.0,
-- and you may not use this file except in compliance with the Apache License Version 2.0.
-- You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the Apache License Version 2.0 is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.
--
-- Version:     0.1.1
--
-- Authors:     Christophe Bogaert
-- Copyright:   Copyright (c) 2016 Snowplow Analytics Ltd
-- License:     Apache License Version 2.0

DROP TABLE IF EXISTS {{.scratch_schema}}.web_events_time;
CREATE TABLE {{.scratch_schema}}.web_events_time
  DISTKEY(page_view_id)
  SORTKEY(page_view_id)
AS (

  SELECT

    wp.page_view_id,

    MIN(ev.derived_tstamp) AS min_tstamp, -- requires the derived timestamp (JS tracker 2.6.0+ and Snowplow 71+)
    MAX(ev.derived_tstamp) AS max_tstamp, -- requires the derived timestamp (JS tracker 2.6.0+ and Snowplow 71+)

    SUM(CASE WHEN ev.event_name = 'page_view' THEN 1 ELSE 0 END) AS pv_count, -- for debugging
    SUM(CASE WHEN ev.event_name = 'page_ping' THEN 1 ELSE 0 END) AS pp_count, -- for debugging

    {{.heartbeat}} * COUNT(DISTINCT(FLOOR(EXTRACT(EPOCH FROM ev.derived_tstamp)/{{.heartbeat}}))) - {{.first_ping}} AS time_engaged_in_s -- assumes 10 seconds between subsequent page pings

  FROM {{.input_schema}}.events AS ev

  INNER JOIN {{.scratch_schema}}.web_page_context AS wp
    ON ev.event_id = wp.root_id

  WHERE ev.event_name IN ('page_view', 'page_ping')
  AND ev.derived_tstamp BETWEEN '2010-01-01' AND GETDATE()

  GROUP BY 1

);
