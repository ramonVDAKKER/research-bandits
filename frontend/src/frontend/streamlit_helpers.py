"""Streamlit helper utilities for page initialization."""

import streamlit as st


def init_page():
    """Initialize Streamlit page configuration and session state."""
    if "init_page" not in st.session_state:
        st.set_page_config(layout="wide")
        st.session_state["init_page"] = True

    if "dgp_is_set" not in st.session_state:
        st.session_state.dgp_is_set = False
