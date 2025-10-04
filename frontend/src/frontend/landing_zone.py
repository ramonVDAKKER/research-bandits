"""Streamlit landing zone - main navigation configuration."""

import streamlit as st

page_dgp = st.Page(
    "dgp.py", title="Data Generating Process", icon=":material/settings:"
)
# page_arm_pull_distribution = st.Page(
#     "arm_pull_distributions.py", title="Arm pull distribution", icon=":material/analytics:")
# page_regret_distribution = st.Page(
#     "regret_distributions.py", title="Regret distribution", icon=":material/analytics:")

pages = {
    "Settings": [page_dgp],
    #  "Monte Carlo results": [
    #     page_arm_pull_distribution,
    #     page_regret_distribution,
    #  ],
}

pg = st.navigation(pages=pages, expanded=True)
pg.run()
