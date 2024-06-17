#!/usr/bin/python3

from sys import argv
from xvfbwrapper import Xvfb
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions
from selenium.webdriver.firefox.service import Service
import re

print("Admin password " + argv[1])

with Xvfb() as xvfb:

	service = Service(executable_path = "/usr/local/bin/geckodriver", log_path = "/tmp/geckodriver.log")
	driver = webdriver.Firefox(service = service)

	driver.get("http://localhost")
	print(driver.title)
	assert "Kerberos setup" in driver.title

	pre = driver.find_element("xpath", "//pre")
	print(pre.text)

	kinit_form = driver.find_element("xpath", "//form[input[@type = 'hidden'][@name = 'kinit']]")
	kinit_form.find_element("id", "username").send_keys("admin")
	kinit_form.find_element("id", "password").send_keys(argv[1])
	print("Submitting kinit")
	html = driver.find_element("xpath", "/html")
	kinit_form.submit()
	WebDriverWait(driver, 15).until(expected_conditions.staleness_of(html))

	pre = driver.find_element("xpath", "//pre")
	print(pre.text)
	assert "Valid starting" in pre.text
	assert "krbtgt/EXAMPLE.TEST@EXAMPLE.TEST" in pre.text

	driver.get("https://www.example.test/")
	title = driver.find_element("xpath", "//h1/a")
	print(title.text)
	assert "Not logged in" in title.text

	logon_link = driver.find_element("xpath", "//a[@href][text() = 'login']")
	html = driver.find_element("xpath", "/html")
	logon_link.click()
	WebDriverWait(driver, 15).until(expected_conditions.staleness_of(html))
	print(driver.current_url)

	title = driver.find_element("xpath", "//h1/a")
	print(title.text)
	assert "Logged in as admin" in title.text

	groups = driver.find_element("xpath", "//tr[td/text() = 'Member of groups']/td[2]")
	print(groups.text)
	assert "ext:admins" in groups.text

	driver.get("http://localhost")
	assert "Kerberos setup" in driver.title
	print("Submitting kdestroy")
	html = driver.find_element("xpath", "/html")
	driver.find_element("name", "kdestroy").submit()
	WebDriverWait(driver, 15).until(expected_conditions.staleness_of(html))

	pre = driver.find_element("xpath", "//pre")
	print(pre.text)
	assert re.match("klist: No credentials cache found|klist: Credentials cache keyring 'persistent:456:456' not found", pre.text)

	driver.quit()
