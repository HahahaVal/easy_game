#!/usr/bin/python
# -*- coding: utf-8 -*-

#getroot获得rootNodes，递归遍历rootNodes[0]解析成lua
import xml.etree.ElementTree as ET
import sys
import os
import re
import unicodedata

XML_EXT = ".xml"
BT_XML_PATH = "./BehaviacTree/exported"
BT_LUA_PATH = "./"

LUA_FILE_FORMAT = \
	'local bt = {{\n' \
	'{0}'\
	'}}\n' \
	'return bt' \

if len(sys.argv) >= 2:
	BT_XML_PATH = sys.argv[1]

reload(sys)
sys.setdefaultencoding('utf-8')

def is_number(value):
	try:
		float(value)
		return True
	except ValueError:
		pass

	try:
		unicodedata.numeric(value)
		return True
	except (TypeError, ValueError):
		pass

	return False


def to_lua_value(input_str):
	if input_str == "true":
		return input_str
	elif input_str == "false":
		return input_str
	elif input_str == "null":
		return "nil"
	elif is_number(input_str):
		return str(input_str)
	return "\"" + input_str + "\""


def convert_param_error(op_str):
	raise Exception("param is too much do not do that shit!"+op_str)


def conver_value(input_str):
	match_obj = re.match(r'.*[ :]([\-\w]+)$', input_str)	#匹配类属性、枚举、结构体属性
	if match_obj:
		input_str = match_obj.group(1)
	return to_lua_value(input_str)


def convert_op_param(op_str):
	s_type = 0
	value = ""
	match_obj = re.match(r'.*::(\w+)\(.*\)', op_str)	#匹配方法
	if match_obj:
		s_type = 2
		value = "\"" + match_obj.group(1) + "\""
	else:
		match_obj = re.match(r'.*[ :]+(.*)$', op_str)	#值类型匹配
		if match_obj:
			s_type = 1
			value = to_lua_value(match_obj.group(1))
		else:
			match_obj = re.match(r'.*::(\w+)$', op_str)	#匹配类属性、枚举、结构体属性
			if match_obj:
				s_type = 3
				value = "\""+match_obj.group(1)+"\""
			else:
				value = "\""+op_str+"\""

	paramStr = convert_params(op_str)
    paramLuaTable = "{"
    if paramStr:
        params = paramStr.split(',')
        for param in params:
            if param.isdigit():
                paramLuaTable = paramLuaTable + param + ","
    paramLuaTable = paramLuaTable + "}"

    return "{{ type = {0}, value = {1}, params = {2} }}".format(s_type, value, paramLuaTable)


def convert_method(op_str):
	match_obj = re.match(r'.*::(\w+)\(.*\)', op_str)
	if match_obj:
		return '"{}"'.format(match_obj.group(1))


def convert_params(op_str):
	match_obj = re.match(".*\((.*)\).*", op_str)
	if match_obj:
		return match_obj.group(1)


DICT_PROPERTY = {
	"Opl": convert_op_param,
	"Opl1": convert_op_param,
	"Opl2": convert_op_param,
	"Opl3": convert_op_param,
	"Opl4": convert_op_param,
	"Opl5": convert_param_error,
	"Opr": convert_op_param,
	"Opr1": convert_op_param,
	"Opr2": convert_op_param,
	"Opr3": convert_op_param,
	"Opr4": convert_op_param,
	"Opr5": convert_param_error,
	"Method": convert_method,
	"Count": conver_value,
	"DecorateWhenChildEnds":conver_value,
	"EndOutside":conver_value,
	"EndStatus":conver_value,
	"ResultFunctor":convert_method,
}


class Convertor:
	def __init__(self, node):
		self.node = node
		self.out_list = []
		self.indent = ""

	def __add_line(self, line):
		self.out_list.append(self.indent + line)

	def __walk_node(self, node):
		self.indent += "\t"
		self.__add_line("{")
		self.indent += "\t"
		node_list = []
		precondition_list = []
		effector_list = []
		self.__add_line('type = "{0}",'.format(node.attrib['class']))
		self.__add_line("id = {0},".format(node.attrib['id']))
		for child in node:
			tag = child.tag
			if tag == "node":
				node_list.append(child)

			elif tag == "attachment":
				class_type = child.attrib['class']
				if class_type == "Precondition":
					precondition_list.append(child)
				elif class_type == "Effector":
					effector_list.append(child)

			elif tag == "property":
				attrib_list = child.attrib.items()
				if len(attrib_list) > 1:
					raise Exception("不支持有属性的节点")
				attr = attrib_list[0]
				attr_name = attr[0]
				attr_value = attr[1]
				convert_func = DICT_PROPERTY.get(attr_name)
				if convert_func:
					self.__add_line('{0} = {1},'.format(str(attr_name), convert_func(attr_value)))
				else:
					self.__add_line('{0} = "{1}",'.format(str(attr_name), str(attr_value)))

				if attr_name == "Method":
					paramStr = convert_params(attr_value)
					params = paramStr.split(',')
					paramLuaTable = "{"
					for param in params:
						if param.isdigit():
							paramLuaTable = paramLuaTable + param + ","
					paramLuaTable = paramLuaTable + "}"
					self.__add_line('{0} = {1},'.format("params", paramLuaTable))


		if len(node_list) > 0:
			self.__add_line("nodeList = {")
			for next_node in node_list:
				self.__walk_node(next_node)
			self.__add_line("},")

		if len(precondition_list) > 0:
			self.__add_line("preconditionList = {")
			for next_node in precondition_list:
				self.__walk_node(next_node)
			self.__add_line("},")

		if len(effector_list) > 0:
			self.__add_line("effectorList = {")
			for next_node in effector_list:
				self.__walk_node(next_node)
			self.__add_line("},")

		self.indent = self.indent[:-1]
		self.__add_line("},")
		self.indent = self.indent[:-1]

	def walk_node(self):
		self.__walk_node(self.node[0])

	def get_string(self):
		return "\n".join(self.out_list)


def convert_xml_to_lua(file_path, file_name):
	root = ET.parse(file_path).getroot()
	if root.tag != "behavior":
		return
	
	convertor = Convertor(root)
	convertor.walk_node()

	lua_file = open(BT_LUA_PATH + file_name + ".lua" , "w+")
	lua_file.write(LUA_FILE_FORMAT.format(convertor.get_string()))


if __name__ == '__main__':
	fileList = []
	for root, dirs, files in os.walk(BT_XML_PATH):
		for file_full_name in files:
			filename, ext = os.path.splitext(file_full_name)
			if ext == XML_EXT:
				convert_xml_to_lua(os.path.join(root, file_full_name), filename)
