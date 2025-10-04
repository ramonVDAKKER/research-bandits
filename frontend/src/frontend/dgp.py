"""Data Generating Process page - manage and generate data files."""

import os

import streamlit as st

from frontend.data_manager import DataManager

# Initialize data manager
storage_path = os.getenv("STORAGE_PATH", "/data")
backend_image = os.getenv("BACKEND_IMAGE", "research-bandits-backend")
dm = DataManager(storage_path=storage_path, backend_image=backend_image)

st.title("Data Generating Process")

# Section 1: Generate new data
st.header("Generate New Data")

col1, col2, col3 = st.columns(3)

with col1:
    rows = st.number_input(
        "Number of rows", min_value=100, max_value=1_000_000, value=1000, step=100
    )

with col2:
    cols = st.number_input(
        "Number of columns", min_value=1, max_value=100, value=10, step=1
    )

with col3:
    custom_filename = st.text_input("Filename (optional)", placeholder="data_custom")

if st.button("Generate Data", type="primary", use_container_width=True):
    with st.spinner("Running batch job to generate data..."):
        result = dm.generate_data(
            rows=rows, cols=cols, filename=custom_filename if custom_filename else None
        )

        if result["status"] == "success":
            st.success("Data generated successfully!")
            st.code(result["logs"], language="text")
            st.rerun()
        else:
            st.error("Failed to generate data")
            st.code(result["logs"], language="text")

st.divider()

# Section 2: Available data files
st.header("Available Data Files")

files = dm.list_files()

if not files:
    st.info("No data files available yet. Generate some data above!")
else:
    st.write(f"Found **{len(files)}** data file(s):")

    for file_info in files:
        col1, col2, col3, col4 = st.columns([3, 1, 2, 1])

        with col1:
            st.text(file_info["filename"])

        with col2:
            st.text(f"{file_info['size_mb']} MB")

        with col3:
            st.text(file_info["modified"])

        with col4:
            if st.button(
                "🗑️", key=f"delete_{file_info['filename']}", help="Delete file"
            ):
                if dm.delete_file(str(file_info["filename"])):
                    st.success(f"Deleted {file_info['filename']}")
                    st.rerun()
                else:
                    st.error("Failed to delete file")

# import numpy as np
# import streamlit as st
# # from bandits.monte_carlo_helpers import EvaluateGaussianMAB, simulate_standard_normal
# # from bandits.policies import UCB, EpsilonGreedy, GaussianThompson
# from streamlit_app.streamlit_helpers import init_page

# init_page()

# if "policies" not in st.session_state:
#     st.session_state["policies"] = []

# if "arm_distribution_confirmed" not in st.session_state:
#     st.session_state["arm_distribution_confirmed"] = False

# if "confirmed_policies" not in st.session_state:
#     st.session_state["confirmed_policies"] = False

# with st.sidebar:
#     if st.button("Reset settings", key="reset_settings", icon=":material/refresh:"):
#         st.session_state["policies"] = []
#         st.session_state["arm_distribution_confirmed"] = False
#         st.session_state["confirmed_policies"] = False
#         st.rerun()


# st.markdown("### Settings")

# with st.expander("General settings", expanded=True):
#     number_of_mc_replications = st.number_input("Number of Monte Carlo replications", min_value=1_000, max_value=50_000, value=1_000, step=1_000)
#     maximum_number_of_rounds = st.number_input("Maximum number of rounds *T*", min_value=100, max_value=1_000, value=250, step=50)

# with st.expander("Arm distribution parameters", expanded=(not st.session_state["arm_distribution_confirmed"])):

#     st.markdown("""
#         This dashboard considers the Gaussian Multi-Armed Bandit (MAB) problem, where the rewards of each arm are drawn from a
#         Gaussian distribution with known variance. As the variances are known, we can assume -- without loss of generality -- that they are equal to 1.
#     """)

#     number_of_arms =  st.number_input("Number of arms *K*", min_value=2, max_value=25, value=2, step=1)

#     mu = np.zeros(number_of_arms, dtype=float)
#     for i in range(number_of_arms):
#         mu[i] = st.number_input(f"Mean reward of arm {i+1} (*μ_{i+1}*)", min_value=-10.0, max_value=10.0, value=0.0, step=0.1, key=f"mean_reward_arm_{i+1}")

#     if st.button("Confirm arm distribution parameters", key="confirm_arm_distribution", icon=":material/check:"):
#         st.session_state["number_of_arms"] = number_of_arms
#         st.session_state["mu"] = mu
#         st.session_state["policies"] = []
#         st.session_state["arm_distribution_confirmed"] = True
#         st.rerun()

# with st.expander("Select policies", expanded=(not st.session_state["confirmed_policies"])):
#     if not st.session_state.get("arm_distribution_confirmed", False):
#         st.info("Please first confirm the arm distribution parameters before selecting policies.", icon=":material/info:")
#     else:
#         st.markdown("**Selected policies:**")
#         if len(st.session_state["policies"]) == 0:
#             st.markdown("No policies selected yet.")
#             clear_disabled = True
#             confirm_disabled = True
#         else:
#             clear_disabled = False
#             confirm_disabled = False
#             for policy in st.session_state["policies"]:
#                 st.markdown(f"- {policy['name']}")

#         if st.button("Clear selected policies", key="clear_policies", icon=":material/delete:", disabled=clear_disabled):
#             st.session_state["policies"] = []
#             st.rerun()
#         if st.button("Confirm selected policies", key="confirm_policies", icon=":material/check:", disabled=confirm_disabled):
#             st.session_state["confirmed_policies"] = True
#             st.rerun()


#         st.divider()
#         st.markdown("**Add policies:**")
#         if st.checkbox("Add Epsilon-Greedy"):
#             epsilon = st.number_input("Epsilon value (0.0 to 1.0)", min_value=0.01, max_value=0.99, value=0.1, step=0.01)
#             if st.button(f"Add Epsilon-Greedy", key="confirm_epsilon_greedy", icon=":material/check:"):
#                 policy = lambda K, R=1: EpsilonGreedy(K, R, epsilon=epsilon)
#                 st.session_state["policies"].append({"name": f"epsilon_greedy (ε={epsilon})", "policy": policy})
#                 st.rerun()
#         if st.checkbox("UCB1"):
#             if st.button(f"Confirm UCB1", key="confirm_ucb1", icon=":material/check:"):
#                 policy = lambda K, R=1:  UCB(K, R, c=1.0)
#                 st.session_state["policies"].append({"name": "ucb1", "policy": policy})
#                 st.rerun()
#         if st.checkbox("Thompson Sampling"):
#             if st.button(f"Confirm Thompson Sampling", key="confirm_thompson_sampling", icon=":material/check:"):
#                 policy = lambda K, R=1:  lambda: GaussianThompson(K, R, prior_mean=0.0, prior_var=1.0)
#                 st.session_state["policies"].append({"name": "thompson_sampling", "policy": policy})
#                 st.rerun()


# if st.session_state["arm_distribution_confirmed"] and st.session_state["confirmed_policies"]:
#     st.markdown(f"""Ready to start analysis with
# **{len(st.session_state["policies"])} policies** and **{st.session_state["number_of_arms"]} arms**.
#     """)

#     if st.button("Prepare analysis", icon=":material/arrow_right:"):
#         if len(st.session_state["policies"]) == 0:
#             st.error("Please select at least one policy to run the analysis.")
#             st.stop()
#         with st.spinner("Preparing analysis..."):
#             st.session_state["mu"] = mu
#             st.session_state["maximum_number_of_rounds"] = maximum_number_of_rounds
#             st.session_state["number_of_mc_replications"] = number_of_mc_replications
#             st.session_state["number_of_arms"] = number_of_arms
#             st.session_state["noise"] = simulate_standard_normal(maximum_number_of_rounds, number_of_arms, number_of_mc_replications)

#             results = {}
#             study = EvaluateGaussianMAB(
#                 simulated_noise=st.session_state["noise"],
#             )
#             for p in st.session_state["policies"]:
#                 name = p["name"]
#                 policy_factory = p["policy"]
#                 print(f"Running policy: {name}")
#                 results[name] = study.generate_outcomes(mu, policy_factory)

#             st.session_state["analysis"] = {
#                     "number_of_mc_replications": number_of_mc_replications,
#                     "maximum_number_of_rounds": maximum_number_of_rounds,
#                     "number_of_arms": number_of_arms,
#                     "mu": mu,
#                     "noise": st.session_state["noise"],
#                     "policies": st.session_state["policies"],
#                     "results": results
#                 }
