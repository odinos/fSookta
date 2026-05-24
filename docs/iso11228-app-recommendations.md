# ISO 11228 recommendation mapping

This app uses the ISO 11228 reference documents supplied by the research team as a practical recommendation layer after REBA/ISO risk calculation.

## Sources reviewed

- `/Users/kpc/Documents/Doc/fortrain/ISO-11228-1-2021.pdf`
- `/Users/kpc/Documents/Doc/fortrain/ISO-11228-2-2007.pdf`
- `/Users/kpc/Documents/Doc/fortrain/ISO-11228-3-2007.pdf`
- `/Users/kpc/Documents/Doc/อธิบายวิธีการ และสรุปผล ISO 11228.pdf`

## App mapping

The app keeps the user-facing text short and action-oriented. It does not reproduce the standard text verbatim.

| ISO area | App recommendation keys |
| --- | --- |
| ISO 11228-1 lifting/carrying: load, horizontal reach, lift height, frequency, grip, recovery | `act_reduce_weight`, `act_iso_keep_load_close`, `act_iso_lift_height`, `act_iso_reduce_frequency`, `act_iso_improve_grip`, `act_iso_plan_recovery`, `act_use_cart_distance` |
| ISO 11228-2 pushing/pulling: force, posture, handles, floor/route, distance, smooth movement | `act_check_wheels`, `act_use_legs`, `act_iso_push_smooth`, `act_iso_push_handle_height`, `act_iso_floor_level`, `act_iso_reduce_push_distance`, `act_iso_push_not_pull` |
| ISO 11228-3 repetitive low-load work: recovery, task variation, neutral reach, grip/tool design | `act_iso_plan_recovery`, `act_iso_job_rotation`, `act_iso_neutral_reach`, `act_iso_tool_handle_fit` |

## Runtime behavior

- REBA recommendations are still produced for all activities.
- ISO 11228-1 recommendations are added when lifting/carrying inputs show higher exposure such as long reach, non-ideal height, high frequency, long duration, or long transport distance.
- ISO 11228-2 recommendations are added when push/pull force or distance is high.
- ISO 11228-3-style recommendations are added when REBA activity/repetition or upper-limb posture indicates repeated low-load exposure.
