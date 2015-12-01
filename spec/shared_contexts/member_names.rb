shared_context 'member names' do
  include JSONAPIObjects
  CharacterRange = JSONAPIonify::CharacterRange

  # Member Names
  # ============
  describe 'member names' do
    #
    # All member names used in a JSON API document **MUST** be treated as case sensitive
    # by clients and servers, and they **MUST** meet all of the following conditions:
    #
    # - Member names **MUST** contain at least one character.
    describe 'must contain at least one character' do

    end

    # - Member names **MUST** contain only the allowed characters listed below.
    # - Member names **MUST** start and end with a "globally allowed character",
    #   as defined below.
    #
    # To enable an easy mapping of member names to URLs, it is **RECOMMENDED** that
    # member names use only non-reserved, URL safe characters specified in [RFC 3986](http://tools.ietf.org/html/rfc3986#page-13).
    #
    # Allowed Characters
    # ==================
    describe 'contains allowed characters' do
      # The following "globally allowed characters" **MAY** be used anywhere in a member name:
      context 'valid characters' do
        ranges = [
          CharacterRange["\u0061", "\u007A"], # " "a-z"
          CharacterRange["\u0041", "\u005A"], # " "A-Z"
          CharacterRange["\u0030", "\u0039"], # " "0-9"
          CharacterRange["\u0080", "\uFFFF"] # any UNICODE character except U+0000 to U+007F (not recommended, not URL safe)
        ]
        ranges.each do |range|
          context "given the range #{range}" do
            key  = range.reduce(:<<)
            data = { "a#{key}a".to_sym => 1 }
            it_should_behave_like 'a valid jsonapi object', data
          end
        end
      end

      # Additionally, the following characters are allowed in member names, except as the
      # first or last character:
      describe 'does not start or end with an invalid character' do
        chars = [
          "\u002D", # HYPHEN-MINUS, "-"
          "\u005F", # LOW LINE, "_"
          "\u0020" # SPACE, " " (not recommended, not URL safe)
        ]

        chars.each do |char|
          context "when starting with `#{char}`" do
            data = { "#{char}a".to_sym => 1 }
            it_should_behave_like 'an invalid jsonapi object', data
          end

          context "when ending with `#{char}`" do
            data = { "a#{char}".to_sym => 1 }
            it_should_behave_like 'an invalid jsonapi object', data
          end

          context "when containing but not starting or ending with `#{char}`" do
            data = { "a#{char}a".to_sym => 1 }
            it_should_behave_like 'a valid jsonapi object', data
          end
        end
      end

      # Reserved Characters
      # ===================
      #
      # The following characters **MUST NOT** be used in member names:
      context 'invalid characters' do
        chars = [
          "\u002B", # PLUS SIGN, "+" (used for ordering)
          "\u002C", # COMMA, "," (used as a separator between relationship paths)
          "\u002E", # PERIOD, "." (used as a separator within relationship paths)
          "\u005B", # LEFT SQUARE BRACKET, "[" (used in sparse fieldsets)
          "\u005D", # RIGHT SQUARE BRACKET, "]" (used in sparse fieldsets)
          "\u0021", # EXCLAMATION MARK, "!"
          "\u0022", # QUOTATION MARK, '"'
          "\u0023", # NUMBER SIGN, "#"
          "\u0024", # DOLLAR SIGN, "$"
          "\u0025", # PERCENT SIGN, "%"
          "\u0026", # AMPERSAND, "&"
          "\u0027", # APOSTROPHE, "'"
          "\u0028", # LEFT PARENTHESIS, "("
          "\u0029", # RIGHT PARENTHESIS, ")"
          "\u002A", # ASTERISK, "&#x2a;"
          "\u002F", # SOLIDUS, "/"
          "\u003A", # COLON, ":"
          "\u003B", # SEMICOLON, ";"
          "\u003C", # LESS-THAN SIGN, "<"
          "\u003D", # EQUALS SIGN, "="
          "\u003E", # GREATER-THAN SIGN, ">"
          "\u003F", # QUESTION MARK, "?"
          "\u0040", # COMMERCIAL AT, "@"
          "\u005C", # REVERSE SOLIDUS, "\"
          "\u005E", # CIRCUMFLEX ACCENT, "^"
          "\u0060", # GRAVE ACCENT, "&#x60;"
          "\u007B", # LEFT CURLY BRACKET, "{"
          "\u007C", # VERTICAL LINE, "|"
          "\u007D", # RIGHT CURLY BRACKET, "}"
          "\u007E" # TILDE, "~"
        ]
        chars.each do |char|
          context "given the char `#{char}`" do
            data = { "a#{char}a".to_sym => 1 }
            it_should_behave_like 'an invalid jsonapi object', data
          end
        end
      end
    end

  end
end
