install_pileven.sh: install_pileven_header.sh install_pileven_footer.sh set_pin_alt.py
	cat install_pileven_header.sh set_pin_alt.py install_pileven_footer.sh > install_pileven.sh
	chmod +x install_pileven.sh

