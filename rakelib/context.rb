require 'fileutils'
require_relative '../lib/rawww'
require_relative '../lib/series'
include Rawww

CONFIG = Config.instance
RAW = CONFIG.raw
WWW = CONFIG.www
