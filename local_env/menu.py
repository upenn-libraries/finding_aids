"""Menu functions."""
# local_env/menu.py

import glob
from typing import List
from pygments import formatters, highlight, lexers
from pygments.util import ClassNotFound
from simple_term_menu import TerminalMenu
from local_env import LocalEnvironment


def menu(title: str, items: List[str], preview_command: str = "", preview_size: float = 0.0) -> TerminalMenu:
    """Builds the menu

    Args:
        title (str): The menu title
        items (List[str]): The menu items
        preview_command (str, optional): Command to run when previewing item. Defaults to "".
        preview_size (float, optional): The item preview size. Defaults to 0.0.

    Returns:
        TerminalMenu: _description_
    """
    try:
        return TerminalMenu(
            menu_entries=items,
            title=title,
            clear_screen=True,
            preview_command=preview_command,
            preview_size=preview_size
        )
    except Exception as exception:
        raise exception


def preview_file(filepath: str) -> str:
    """Preview the selected file via the command line

    Args:
        filepath (str): The filepath of the file to preview

    Returns:
        str: Return a formatted preview of the file
    """
    with open(filepath, "r") as f:
        file_content = f.read()

    try:
        lexer = lexers.get_lexer_for_filename(
            filepath, stripnl=False, stripall=False)
    except ClassNotFound:
        lexer = lexers.get_lexer_by_name("text", stripnl=False, stripall=False)

    formatter = formatters.TerminalFormatter(bg="dark")
    return highlight(file_content, lexer, formatter)


def list_files(directory: str = "../ansible/inventories/**/*.yml") -> List[str]:
    """Recursively grab a list of files given a directory string

    Args:
        directory (str, optional): Directory to crawl. Default to "../ansible/inventories/**/*.yml"

    Returns:
        List[str]: A list of files
    """
    return glob.glob(directory, recursive=True)


def render_menu(local_env: LocalEnvironment):
    """Render the menu

    Args:
        local_env (LocalEnvironment): The dev environment class
    """
    # Primary menu settings
    main_menu_title = "  Main Menu.\n  Press Q or Esc to quit. \n"
    main_menu_exit = False
    main_menu_items = ["[1] Start local dev env",
                       "[2] Remove local dev env",
                       "[3] Edit vault file",
                       "[4] Quit"]
    main_menu = menu(main_menu_title, main_menu_items)

    # Secondary menu settings used to determine whether or not to remove the
    # container after creating a stack
    remove_container_menu_title = "  Remove controller container?\n Press Q or Esc to back to main menu. \n"
    remove_container_menu_items = ["[1] Yes", "[2] No", "[3] Back"]
    remove_container_menu_back = False
    remove_container_menu = menu(remove_container_menu_title, remove_container_menu_items)

    # Secondary menu used to select which vault file to edit
    vault_file_menu_title = "  Select file to edit.\n  Press Q or Esc to back to main menu. \n"
    vault_file_menu_back = False
    vault_file_menu = menu(vault_file_menu_title, list_files(), preview_command=preview_file, preview_size=0.75)

    while not main_menu_exit:
        main_sel = main_menu.show()
        if main_sel == 0:  # start local dev env
            while not remove_container_menu_back:
                edit_sel = remove_container_menu.show()
                if edit_sel == 0:  # create and remove controller container
                    main_menu_exit = True
                    remove_container_menu_back = True
                    local_env.handle_stack("create", True)
                elif edit_sel == 1:  # create and keep controller container
                    main_menu_exit = True
                    remove_container_menu_back = True
                    local_env.handle_stack("create", False)
                elif edit_sel == 2 or edit_sel is None:  # exit to main menu
                    remove_container_menu_back = True
                    print("Back Selected")
            remove_container_menu_back = False
        elif main_sel == 1:  # remove local dev env
            main_menu_exit = True
            local_env.handle_stack("destroy")
        elif main_sel == 2:  # edit vault file
            while not vault_file_menu_back:
                edit_sel = vault_file_menu.show()
                if edit_sel is None:   # exit to main menu
                    vault_file_menu_back = True
                    print("Back Selected")
                else:   # select vault file to edit
                    main_menu_exit = True
                    vault_file_menu_back = True
                    local_env.edit_ansible_vault_file(
                        list_files()[edit_sel].replace("../ansible/", ""))
            vault_file_menu_back = False
        elif main_sel == 3 or main_sel is None:  # quit
            main_menu_exit = True
            print("Quit Selected")
