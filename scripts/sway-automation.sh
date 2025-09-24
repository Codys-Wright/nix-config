#!/usr/bin/env bash

# Sway automation script for headless sessions
# This script can be run against an existing Sway session

# Configuration
SWAYSOCK="/tmp/sway-headless-ipc.sock"
WAYLAND_DISPLAY="wayland-1"

# Set environment variables
export SWAYSOCK="$SWAYSOCK"
export WAYLAND_DISPLAY="$WAYLAND_DISPLAY"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if Sway is running
check_sway() {
    if ! swaymsg -t get_outputs > /dev/null 2>&1; then
        echo -e "${RED}Error: Cannot connect to Sway session${NC}"
        echo "Make sure your headless Sway is running with socket: $SWAYSOCK"
        exit 1
    fi
    echo -e "${GREEN}✅ Connected to Sway session${NC}"
}

# Function to show help
show_help() {
    echo "Sway Automation Script"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  launch <app>           - Launch an application"
    echo "  type <text>            - Type text using wvkbd"
    echo "  key <key>              - Send key press (e.g., enter, ctrl+c)"
    echo "  click <button>         - Click mouse button (left, right, middle)"
    echo "  move <x> <y>           - Move cursor to position (0.0-1.0)"
    echo "  scroll <amount>        - Scroll (positive=up, negative=down)"
    echo "  focus <direction>      - Focus window (left, right, up, down)"
    echo "  workspace <number>     - Switch to workspace"
    echo "  vkbd                   - Start virtual keyboard daemon"
    echo "  coords                 - Get coordinates by clicking (using slurp)"
    echo "  clickat <x> <y>        - Click at specific pixel coordinates"
    echo "  status                 - Show current status"
    echo "  tree                   - Show window tree"
    echo "  interactive            - Start interactive mode"
    echo ""
    echo "Examples:"
    echo "  $0 launch firefox"
    echo "  $0 type 'Hello World'"
    echo "  $0 key enter"
    echo "  $0 click left"
    echo "  $0 move 0.5 0.5"
    echo "  $0 scroll 3"
    echo "  $0 focus right"
    echo "  $0 workspace 2"
    echo "  $0 coords"
    echo "  $0 clickat 100 200"
}

# Function to launch application
launch_app() {
    local app="$1"
    if [ -z "$app" ]; then
        echo -e "${RED}Error: Please specify an application to launch${NC}"
        return 1
    fi
    echo -e "${YELLOW}Launching $app...${NC}"
    swaymsg exec "$app"
}

# Function to start virtual keyboard daemon
start_virtual_keyboard() {
    echo -e "${YELLOW}Starting virtual keyboard daemon...${NC}"
    swaymsg exec "WAYLAND_DISPLAY=$WAYLAND_DISPLAY wvkbd --daemon"
    echo -e "${GREEN}Virtual keyboard daemon started${NC}"
}

# Function to type text
type_text() {
    local text="$1"
    if [ -z "$text" ]; then
        echo -e "${RED}Error: Please specify text to type${NC}"
        return 1
    fi
    echo -e "${YELLOW}Typing: $text${NC}"
    # Use wvkbd for Wayland virtual keyboard input
    swaymsg exec "WAYLAND_DISPLAY=$WAYLAND_DISPLAY wvkbd --text '$text'"
}

# Function to send key
send_key() {
    local key="$1"
    if [ -z "$key" ]; then
        echo -e "${RED}Error: Please specify a key${NC}"
        return 1
    fi
    echo -e "${YELLOW}Sending key: $key${NC}"
    # Use wvkbd for Wayland virtual keyboard input
    swaymsg exec "WAYLAND_DISPLAY=$WAYLAND_DISPLAY wvkbd --key '$key'"
}

# Function to click mouse
click_mouse() {
    local button="$1"
    if [ -z "$button" ]; then
        echo -e "${RED}Error: Please specify button (left, right, middle)${NC}"
        return 1
    fi
    echo -e "${YELLOW}Clicking $button button${NC}"
    swaymsg "seat * cursor press button$button"
    sleep 0.1
    swaymsg "seat * cursor release button$button"
}

# Function to move cursor
move_cursor() {
    local x="$1"
    local y="$2"
    if [ -z "$x" ] || [ -z "$y" ]; then
        echo -e "${RED}Error: Please specify x and y coordinates (0.0-1.0)${NC}"
        return 1
    fi
    echo -e "${YELLOW}Moving cursor to $x, $y${NC}"
    swaymsg "seat * cursor set $x $y"
}

# Function to scroll
scroll() {
    local amount="$1"
    if [ -z "$amount" ]; then
        echo -e "${RED}Error: Please specify scroll amount${NC}"
        return 1
    fi
    echo -e "${YELLOW}Scrolling $amount${NC}"
    if [ "$amount" -gt 0 ]; then
        swaymsg "seat * cursor press button4"
        swaymsg "seat * cursor release button4"
    else
        swaymsg "seat * cursor press button5"
        swaymsg "seat * cursor release button5"
    fi
}

# Function to get cursor coordinates using slurp
get_coordinates() {
    echo -e "${YELLOW}Click anywhere to get coordinates...${NC}"
    echo -e "${CYAN}Press Ctrl+C to cancel${NC}"
    echo -e "${CYAN}The coordinates will be displayed in the Sway console/logs${NC}"
    
    # Run slurp within the Sway session
    # The output will appear in the Sway console, not here
    echo -e "${YELLOW}Running slurp in Sway session...${NC}"
    swaymsg exec "WAYLAND_DISPLAY=$WAYLAND_DISPLAY slurp -b 00000000 -p | awk '{print \$1}'"
    
    echo -e "${GREEN}✅ Slurp command executed${NC}"
    echo -e "${CYAN}Check the Sway console/logs for the coordinate output${NC}"
    echo -e "${YELLOW}You can then use: ./scripts/sway-automation.sh clickat <x> <y>${NC}"
}

# Function to click at specific pixel coordinates
click_at_coordinates() {
    local x="$1"
    local y="$2"
    if [ -z "$x" ] || [ -z "$y" ]; then
        echo -e "${RED}Error: Please specify x and y pixel coordinates${NC}"
        return 1
    fi
    echo -e "${YELLOW}Clicking at pixel coordinates ($x, $y)${NC}"
    # Use swaymsg for cursor events with pixel coordinates
    swaymsg "seat * cursor set $x $y"
    sleep 0.1
    swaymsg "seat * cursor press button1"
    sleep 0.1
    swaymsg "seat * cursor release button1"
}

# Function to focus window
focus_window() {
    local direction="$1"
    if [ -z "$direction" ]; then
        echo -e "${RED}Error: Please specify direction (left, right, up, down)${NC}"
        return 1
    fi
    echo -e "${YELLOW}Focusing $direction${NC}"
    swaymsg "focus $direction"
}

# Function to switch workspace
switch_workspace() {
    local workspace="$1"
    if [ -z "$workspace" ]; then
        echo -e "${RED}Error: Please specify workspace number${NC}"
        return 1
    fi
    echo -e "${YELLOW}Switching to workspace $workspace${NC}"
    swaymsg "workspace number $workspace"
}

# Function to show status
show_status() {
    echo -e "${GREEN}=== Sway Session Status ===${NC}"
    echo "Socket: $SWAYSOCK"
    echo "Wayland Display: $WAYLAND_DISPLAY"
    echo ""
    echo -e "${YELLOW}Outputs:${NC}"
    swaymsg -t get_outputs | jq -r '.[] | "  \(.name): \(.current_mode.width)x\(.current_mode.height)"'
    echo ""
    echo -e "${YELLOW}Workspaces:${NC}"
    swaymsg -t get_workspaces | jq -r '.[] | "  \(.name): \(.focused // false)"'
    echo ""
    echo -e "${YELLOW}Windows:${NC}"
    swaymsg -t get_tree | jq -r '.. | select(.type? == "con" and .name? != null) | "  \(.name)"'
}

# Function to show tree
show_tree() {
    swaymsg -t get_tree | jq .
}

# Interactive mode
interactive_mode() {
    echo -e "${GREEN}=== Interactive Sway Automation ===${NC}"
    echo "Type 'help' for commands, 'quit' to exit"
    echo ""
    
    while true; do
        read -p "sway> " cmd args
        case "$cmd" in
            "quit"|"exit")
                echo "Goodbye!"
                break
                ;;
            "help")
                show_help
                ;;
            "launch")
                launch_app "$args"
                ;;
            "type")
                type_text "$args"
                ;;
            "key")
                send_key "$args"
                ;;
            "click")
                click_mouse "$args"
                ;;
            "move")
                move_cursor $args
                ;;
            "scroll")
                scroll "$args"
                ;;
            "focus")
                focus_window "$args"
                ;;
            "workspace")
                switch_workspace "$args"
                ;;
            "coords")
                get_coordinates
                ;;
            "clickat")
                click_at_coordinates $args
                ;;
            "status")
                show_status
                ;;
            "tree")
                show_tree
                ;;
            "")
                continue
                ;;
            *)
                echo -e "${RED}Unknown command: $cmd${NC}"
                echo "Type 'help' for available commands"
                ;;
        esac
    done
}

# Main script logic
main() {
    # Check if Sway is running
    check_sway
    
    # Parse command line arguments
    case "$1" in
        "launch")
            launch_app "$2"
            ;;
        "type")
            type_text "$2"
            ;;
        "key")
            send_key "$2"
            ;;
        "click")
            click_mouse "$2"
            ;;
        "move")
            move_cursor "$2" "$3"
            ;;
        "scroll")
            scroll "$2"
            ;;
        "focus")
            focus_window "$2"
            ;;
        "workspace")
            switch_workspace "$2"
            ;;
        "vkbd")
            start_virtual_keyboard
            ;;
        "coords")
            get_coordinates
            ;;
        "clickat")
            click_at_coordinates "$2" "$3"
            ;;
        "status")
            show_status
            ;;
        "tree")
            show_tree
            ;;
        "interactive"|"i")
            interactive_mode
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
