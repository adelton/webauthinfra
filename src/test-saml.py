#!/usr/bin.python3

from sys import argv
from xvfbwrapper import Xvfb
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions

print("Admin password " + argv[1])

with Xvfb() as xvfb:

	driver = webdriver.Firefox(service_log_path = "/tmp/geckodriver.log")

	driver.get("https://www.example.test/")
	title = driver.find_element_by_xpath("//h1/a")
	print(title.text)
	assert "Not logged in" in title.text

	logon_link = driver.find_element_by_link_text("login")
	logon_link.click()
	print(driver.current_url)

	logon_form = driver.find_element_by_xpath("//form[input[@name = 'ipsilon_transaction_id']]")
	logon_form.find_element_by_id("login_name").send_keys("admin")
	logon_form.find_element_by_id("login_password").send_keys(argv[1])
	logon_form.submit()

	WebDriverWait(driver, 15).until(expected_conditions.url_changes(driver.current_url))
	print(driver.current_url)

	title = driver.find_element_by_xpath("//h1/a")
	print(title.text)
	assert "Logged in as admin" in title.text

	groups = driver.find_element_by_xpath("//tr[td/text() = 'Member of groups']/td[2]")
	print(groups.text)
	assert "ext:admins" in groups.text

	driver.quit()
