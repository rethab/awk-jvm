function bail(msg) {
  print "Error: " msg
  exit
}

function ensure(b, ex, offset) {
  if (b != strtonum(ex)) {
    bail("Expected " ex " but got " b " at offset " offset)
  }
}

function read_magic() {
  x = strtonum($IX); ensure(x, "0xCA", IX); IX++;
  x = strtonum($IX); ensure(x, "0xFE", IX); IX++;
  x = strtonum($IX); ensure(x, "0xBA", IX); IX++;
  x = strtonum($IX); ensure(x, "0xBE", IX); IX++;
}

function read_const_pool(    count, i, tag, len, str, y) {
  count = read_u2();
  for (i = 1; i < count; i++) {
    tag = read_u1();
    CP[i]["tag"] = tag;
    if (tag == 1) {
      # string literal
      len = read_u2();
      str = "";
      for (y = 0; y < len; y++) {
        str = str sprintf("%c", $(y+IX));
      }
      IX += len;
      CP[i]["string"] = str;
    } else if (tag == 7) {
      CP[i]["name_index"] = read_u2();
    } else if (tag == 10) {
      CP[i]["class_index"] = read_u2();
      CP[i]["name_and_type_index"] = read_u2();
    } else if (tag == 12) {
      CP[i]["name_index"] = read_u2();
      CP[i]["descriptor_index"] = read_u2();
    } else {
      bail("Unhandled tag " tag);
    }
  }

}

function read_cp_string(idx) {
  if      (CP[idx]["tag"] ==  1) return CP[idx]["string"];
  else if (CP[idx]["tag"] ==  7) return read_cp_string(CP[idx]["name_index"]);
  else if (CP[idx]["tag"] == 10) return read_cp_string(CP[idx]["name_and_type_index"]);
  else if (CP[idx]["tag"] == 12) return read_cp_string(CP[idx]["name_index"]);
  else bail("Unhandled tag in read_cp_string (" idx ") " CP[idx]["tag"])
}

function read_interfaces(    count, i) {
  count = read_u2();
  for(i = 0; i < count; i++) {
    INTERFACES[i] = read_cp_string(read_u2());
  }
}

function read_attributes(atts,    count, i, n, y) {
  count = read_u2();
  for (i = 0; i < count; i++) {
    atts[i]["name"] = read_cp_string(read_u2());
    n = read_u4();
    for (y = 0; y < n; y++) {
      atts[i]["data"][y] = read_u1();
    }
  }
}

function read_fields(    count, i) {
  count = read_u2();
  if (count != 0) { bail("fields are not supported yet"); }
}

function read_methods(    i, count, y, j) {
  count = read_u2();
  for(i = 0; i < count; i++) {
    METHODS[i]["flags"] = read_u2();
    METHODS[i]["name"] = read_cp_string(read_u2());
    METHODS[i]["descriptor"] = read_cp_string(read_u2());
    read_attributes(atts);
    for (y in atts) {
      METHODS[i]["attributes"][y]["name"] = atts[y]["name"];
      for (j in atts[y]["data"]) {
        METHODS[i]["attributes"][y]["data"][j] = atts[y]["data"][j];
      }
    }
  }
}

function read_u1() {
  x = strtonum($IX); IX++;
  return x;
}

function read_u2() {
  high = strtonum($IX); IX++;
  low  = strtonum($IX); IX++;
  return or(lshift(high, 8), low);
}

function read_u4() {
  high = read_u2();
  low  = read_u2();
  return or(lshift(high, 16), low);
}

function run_frame(name, arg1, arg2,    m, a, d, c, frame, op, stack, sp) {
  for (m in METHODS) {
    if (METHODS[m]["name"] == name) {
      for (a in METHODS[m]["attributes"]) {
        if (METHODS[m]["attributes"][a]["name"] == "Code") {
          frame["maxstack"]  = lshift(METHODS[m]["attributes"][a]["data"][0], 8);
          frame["maxstack"] += METHODS[m]["attributes"][a]["data"][1];
          frame["maxlocals"]  = lshift(METHODS[m]["attributes"][a]["data"][2], 8);
          frame["maxlocals"] += METHODS[m]["attributes"][a]["data"][3];
          frame["codelength"]  = lshift(METHODS[m]["attributes"][a]["data"][4], 24);
          frame["codelength"] += lshift(METHODS[m]["attributes"][a]["data"][5], 16);
          frame["codelength"] += lshift(METHODS[m]["attributes"][a]["data"][6], 8);
          frame["codelength"] += METHODS[m]["attributes"][a]["data"][7];
          for (d = 8; d < frame["codelength"] + 8; d++) {
            frame["code"][d-8] = METHODS[m]["attributes"][a]["data"][d];
          }
          frame["locals"][0] = arg1;
          frame["locals"][1] = arg2;
          break;
        }
      }
    }
  }

  sp = 0;
  for (c in frame["code"]) {
    op = frame["code"][c];

    if (op == 26) { # iload_0
      stack[sp++] = frame["locals"][0];
    } else if (op == 27) { # iload_1
      stack[sp++] = frame["locals"][1];
    } else if (op == 96) { # iadd
      a = stack[--sp];
      b = stack[--sp];
      stack[sp++] = a + b;
    } else if (op == 172) { # ireturn
      return stack[--sp]
    } else {
      bail("Unhandled op " op);
    }
  }

}

{
  IX = 1;

  read_magic()
  minor = read_u2();
  major = read_u2();
  read_const_pool();
  flags = read_u2(); # access flags
  thisname = read_cp_string(read_u2());
  supername = read_cp_string(read_u2());
  read_interfaces();
  read_fields();
  read_methods();
  read_attributes(atts);

  print run_frame("add", 2, 2);
}
