#!/usr/bin/env bash
# Runs Bespren's proof gates the same way on a workstation and in CI.
#
#   GODOT=/path/to/Godot_v4.7.1 tools/ci/run_gates.sh [import] [headless] [enet] [render]
#
# With no suite names it runs all four in order. `render` needs a display: in CI
# the workflow wraps this script in `xvfb-run` with Mesa lavapipe as the Vulkan
# device. A gate passes only when it exits 0 and prints no `FAILED` line; a
# render gate must also report `method=mobile`, because passing
# `--rendering-driver vulkan` alone silently selects Forward+ and the pixels
# would no longer come from the renderer the phone ships.
#
# Gates are listed explicitly so adding one is a decision. Review instruments
# that depend on untracked staging files (rebake candidates, fern/grass macro
# probes, the V3 ecology route fixture) are deliberately not listed here.

set -uo pipefail

GODOT="${GODOT:?set GODOT to a Godot 4.7.1 binary}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${ROOT}/artifacts/ci/logs"
SUMMARY="${ROOT}/artifacts/ci/summary.md"
GATE_TIMEOUT="${GATE_TIMEOUT:-900}"

HEADLESS_GATES=(
	smoke_test
	world_map_validation
	auto_aim_validation
	camera_feedback_validation
	coop_hardening_validation
	damage_feedback_validation
	enemy_impact_validation
	enemy_presentation_validation
	health_readability_validation
	local_environment_validation
	mobile_systems_validation
	player_avatar_readability_validation
	polyhaven_district_validation
	polyhaven_environment_validation
	resource_scatter_validation
	start_menu_layout_validation
	structure_readability_validation
	tactical_hud_validation
	terrain_material_validation
	tower_combat_validation
	vfx_validation
)

ENET_PROBES=(
	enet_peer_probe
	resource_enet_probe
	tactical_enet_probe
)

RENDER_GATES=(
	render_validation
	world_render_validation
	tactical_hud_render_validation
	start_menu_render_validation
	player_presentation_render_validation
	enemy_presentation_render_validation
	enemy_body_readability_render_validation
	enemy_body_combat_readability_render_validation
	structure_visual_render_validation
	structure_readiness_render_validation
	structure_gameplay_scale_render_validation
	core_health_tier_render_validation
	combat_composite_render_validation
	projectile_vfx_ownership_render_validation
	vfx_gameplay_scale_render_validation
	existing_wild_atlas_context_validation
	wilderness_microprop_diversity_validation
)

declare -a RESULTS=()
FAILURES=0

mkdir -p "${LOG_DIR}"
# Eleven capture gates write into res://artifacts/ without creating it, and it
# is gitignored, so a fresh clone needs it made before anything renders.
mkdir -p "${ROOT}/artifacts"

summary_line() {
	# Last line that states a verdict, for the table; never a per-check PASS line.
	grep -E "OK|COMPLETE|FAILED|READY" "$1" | grep -vE "^(PASS|SKIP) \|" | tail -n 1 | cut -c1-140
}

record() {
	local suite="$1" name="$2" status="$3" detail="$4"
	RESULTS+=("| ${suite} | ${name} | ${status} | ${detail//|/\\|} |")
	printf '%-8s %-5s %-50s %s\n' "${suite}" "${status}" "${name}" "${detail}"
	if [[ "${status}" != "ok" ]]; then
		FAILURES=$((FAILURES + 1))
	fi
}

judge() {
	# judge SUITE NAME EXIT_CODE LOG [require_mobile]
	local suite="$1" name="$2" code="$3" log="$4" require_mobile="${5:-}"
	local detail
	detail="$(summary_line "${log}")"
	if [[ "${code}" -ne 0 ]]; then
		record "${suite}" "${name}" "FAIL" "exit ${code}: ${detail}"
	elif grep -q "FAILED" "${log}"; then
		record "${suite}" "${name}" "FAIL" "FAILED in log: ${detail}"
	elif [[ -n "${require_mobile}" ]] && grep -q "method=" "${log}" && ! grep -q "method=mobile" "${log}"; then
		record "${suite}" "${name}" "FAIL" "not the Mobile renderer: ${detail}"
	else
		record "${suite}" "${name}" "ok" "${detail}"
	fi
}

run_import() {
	local log="${LOG_DIR}/import.log"
	timeout "${GATE_TIMEOUT}" "${GODOT}" --headless --editor --path "${ROOT}" --import --quit >"${log}" 2>&1
	local code=$?
	if [[ "${code}" -ne 0 ]] || grep -qE "^(ERROR|SCRIPT ERROR)" "${log}"; then
		record import godot_import FAIL "exit ${code}; see ${log}"
	else
		record import godot_import ok "assets imported"
	fi
}

run_headless() {
	local gate log code
	for gate in "${HEADLESS_GATES[@]}"; do
		log="${LOG_DIR}/${gate}.log"
		timeout "${GATE_TIMEOUT}" "${GODOT}" --headless --path "${ROOT}" --script "res://tests/${gate}.gd" >"${log}" 2>&1
		code=$?
		judge headless "${gate}" "${code}" "${log}"
	done
}

run_enet() {
	local probe host_log client_log host_pid host_code client_code
	for probe in "${ENET_PROBES[@]}"; do
		host_log="${LOG_DIR}/${probe}.host.log"
		client_log="${LOG_DIR}/${probe}.client.log"
		timeout 180 "${GODOT}" --headless --path "${ROOT}" --script "res://tests/${probe}.gd" -- --role=host >"${host_log}" 2>&1 &
		host_pid=$!
		sleep 3
		timeout 180 "${GODOT}" --headless --path "${ROOT}" --script "res://tests/${probe}.gd" -- --role=client >"${client_log}" 2>&1
		client_code=$?
		wait "${host_pid}"
		host_code=$?
		judge enet "${probe}:host" "${host_code}" "${host_log}"
		judge enet "${probe}:client" "${client_code}" "${client_log}"
	done
}

run_render() {
	local gate log code
	for gate in "${RENDER_GATES[@]}"; do
		log="${LOG_DIR}/${gate}.log"
		timeout "${GATE_TIMEOUT}" "${GODOT}" --path "${ROOT}" --rendering-method mobile \
			"res://tests/${gate}.tscn" >"${log}" 2>&1
		code=$?
		judge render "${gate}" "${code}" "${log}" require_mobile
	done
}

suites=("$@")
if [[ ${#suites[@]} -eq 0 ]]; then
	suites=(import headless enet render)
fi
for suite in "${suites[@]}"; do
	case "${suite}" in
		import) run_import ;;
		headless) run_headless ;;
		enet) run_enet ;;
		render) run_render ;;
		*) echo "unknown suite: ${suite}" >&2; exit 2 ;;
	esac
done

{
	echo "## Bespren gates"
	echo
	echo "Godot: \`$("${GODOT}" --version 2>/dev/null | tail -n 1)\` - suites: ${suites[*]} - failures: ${FAILURES}"
	echo
	echo "| suite | gate | status | verdict |"
	echo "|---|---|---|---|"
	printf '%s\n' "${RESULTS[@]}"
} >"${SUMMARY}"

echo
echo "${#RESULTS[@]} results, ${FAILURES} failed. Summary: ${SUMMARY}"
[[ "${FAILURES}" -eq 0 ]]
