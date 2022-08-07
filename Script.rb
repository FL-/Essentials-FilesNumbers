#===============================================================================
# * Pokémon Files by Numbers - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It makes all pokémon sprites and cries
# use National Pokédex number as file name instead of id, like Essentials
# version 18 and earlier.
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above main OR convert into a plugin.
#
# The pokémon files need to be converted to old Essentials format, but, this
# time, using new folders. Checks the below examples. This script won't affect
# egg cracks.
#
#== HOW TO USE =================================================================
#
# This script automatically works after installed. 
#
# At debug menu, in Other Options, you can select "Convert Pokémon symbols to
# numbers" to create a copy of every sprite/cry, but named by National Pokédex
# number. it is recommended to make a backup before.
#
#== EXAMPLES ===================================================================
#
# Naming examples
#
# Graphics/Pokemon/Front/IVYSAUR => Graphics/Pokemon/Front/002
# Graphics/Pokemon/Back/CHARIZARD => Graphics/Pokemon/Back/006b
# Graphics/Pokemon/Front shiny/VENUSAUR_female => Graphics/Pokemon/Front shiny/003fs
# Graphics/Pokemon/Back shiny/DEOXYS_1 => Graphics/Pokemon/Back shiny/386sb_1
# Graphics/Pokemon/Icons/SHELLOS_1 => Graphics/Pokemon/Icons/icon422_1
# Graphics/Pokemon/Eggs/MANAPHY => Graphics/Pokemon/Eggs/490egg
# Graphics/Pokemon/Eggs/MANAPHY_icon => Graphics/Pokemon/Eggs/icon490egg
# Graphics/Pokemon/Footprints/BULBASAUR => Graphics/Pokemon/Footprints/footprint001
# Audio/SE/Cries/GASTRODON_1 => Audio/SE/Cries/423Cry_1
#
# If you set USE_ROOT as true. There are some changes:
#
# Graphics/Pokemon/Front/IVYSAUR => Graphics/Pokemon/002
# Graphics/Pokemon/Back/CHARIZARD => Graphics/Pokemon/006b
# Graphics/Pokemon/Front shiny/VENUSAUR_female => Graphics/Pokemon/003fs
# Graphics/Pokemon/Back shiny/DEOXYS_1 => Graphics/Pokemon/386sb_1
# Graphics/Pokemon/Eggs/MANAPHY => Graphics/Pokemon/490egg
# Graphics/Pokemon/Eggs/MANAPHY_icon => Graphics/Pokemon/Icons/icon490egg
#
#== NOTES ======================================================================
#
# This script can also be used to port new Essentials sprites into old
# Essentials versions.
#
# If you remove a pokémon from PBS, the order became messed.
# 
#===============================================================================

if !PluginManager.installed?("Pokémon Files by Numbers")
  PluginManager.register({                                                 
    :name    => "Pokémon Files by Numbers",                                        
    :version => "1.0",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?t=478574",             
    :credits => "FL"
  })
end

module FileNumber
  # You can change the below value for a quick toggle.
  ENABLED = true

  # When true, all pokémon sprites, except icons, footprints and shadow, go into 
  # Pokemon folder. Egg icons go into Icons folder. 
  # Both debug commands respect this when copying files.
  USE_ROOT = false 

  # You can change here to convert less files per folder if you want to
  # test first.
  CONVERT_QUANTITY = 900_000

  CONVERT_DIR = "Graphics/PokemonConverted/"
  CONVERT_CRY_DIR = "Audio/SE/Cries/PokemonConverted/"

  @@number_per_species = nil
  @@species_per_number = nil
  module_function

  def number_per_species
    if !@@number_per_species
      @@number_per_species = {}
      i = 1
      GameData::Species.each_species { |species|
        @@number_per_species[species.id] = i
        i+=1
      }
    end
    return @@number_per_species
  end

  def species_per_number
    if !@@species_per_number
      @@species_per_number = {}
      i = 1
      GameData::Species.each_species { |species|
        @@species_per_number[i] = species.id
        i+=1
      }
    end
    return @@species_per_number
  end
      
  def getFormattedNumber(species)
    return sprintf("%03d", number_per_species.fetch(species, 0))
  end
      
  def getFormattedSymbol(number)
    return species_per_number.fetch(number, "000").to_s
  end

  def convert_files(symbol_to_number)
    dest_dir = CONVERT_DIR
    Dir.mkdir(dest_dir) if !FileTest.directory?(dest_dir)
    Dir.mkdir(CONVERT_CRY_DIR) if !FileTest.directory?(CONVERT_CRY_DIR)
    folder_array = ["Front/", "Back/", "Front shiny/", "Back shiny/", "Eggs/"]
    special_folder_array = ["Icons/", "Footprints/", "Shadow/"]
    directories_needed = USE_ROOT && symbol_to_number ? special_folder_array+["Eggs/"] : folder_array+special_folder_array
    for ext in directories_needed
      Dir.mkdir(dest_dir + ext) if !FileTest.directory?(dest_dir + ext)
    end
    if symbol_to_number && USE_ROOT
      File.copy("Graphics/Pokemon/Eggs/000_cracks.png", CONVERT_DIR+"Eggs/000_cracks.png")
    end
    convert_pokemon_sprites(symbol_to_number, "Graphics/Pokemon/", dest_dir)
    for ext in folder_array
      convert_pokemon_sprites(symbol_to_number, "Graphics/Pokemon/" + ext, dest_dir)
    end
    convert_pokemon_sprites(symbol_to_number, "Graphics/Pokemon/Shadow/", dest_dir)
    convert_pokemon_icons(symbol_to_number, "Graphics/Pokemon/Icons/", dest_dir)
    convert_pokemon_footprints(symbol_to_number, "Graphics/Pokemon/Footprints/", dest_dir)
    convert_pokemon_cries(symbol_to_number, "Audio/SE/Cries/", CONVERT_CRY_DIR)
    pbSetWindowText(nil)
    pbMessage(_INTL("All found sprites and cries were copied."))
  end
  
  def readDirectoryFiles(directory, formats)
    files = []
    Dir.chdir(directory) {
      for i in 0...formats.length
        Dir.glob(formats[i]) { |f| files.push(f) }
      end
    }
    return files
  end

  def convert_pokemon_filename(symbol_to_number, src_dir, filename, default_prefix = "")
    if symbol_to_number
      return convert_symbol_to_number(src_dir, filename, default_prefix)
    else
      return convert_number_to_symbol(src_dir, filename, default_prefix)
    end
  end

  def convert_number_to_symbol(src_dir, filename, default_prefix = "")
    name = filename
    extension = ".png"
    if filename[/^(.+)\.([^\.]+)$/]   # Of the format something.abc
      name = $~[1]
      extension = "." + $~[2]
    end
    previous_folder = src_dir.split("/")[-1]
    prefix = default_prefix
    form = female = shadow = crack = egg_icon = ""
    if default_prefix == ""
      if (name[/s/] && !name[/shadow/]) || previous_folder[/shiny/]
        prefix = (name[/b/] || previous_folder[/Back/]) ? "Back shiny/" : "Front shiny/"
      else
        prefix = (name[/b/] || previous_folder[/Back/]) ? "Back/" : "Front/"
      end
    elsif default_prefix == "Icons/"
      prefix = "Icons shiny/" if name[/s/] && !name[/shadow/]
    end
    prefix = "Shadow/" if previous_folder[/Shadow/]
    adjusted_name = name
    if name[/egg/] || name[/Egg/]
      prefix = "Eggs/"
      crack = "_icon" if default_prefix == "Icons/"
      # crack = "_cracks" if name[/eggCracks/]
      if name[/icon/]
        adjusted_name = adjusted_name.gsub("icon","").gsub("egg","")
        egg_icon = "_icon"
      end
    end
    species_number = 0
    if adjusted_name[/^(\d+)$/] || adjusted_name[/^(\d+)\D/]    
      species_number = $~[1].to_i
      form = "_" + $~[1].to_s if adjusted_name[/_(\d+)$/] || adjusted_name[/_(\d+)\D/]
    end
    species_data = GameData::Species.try_get(species_per_number[species_number])
    if !species_data || (previous_folder[/Shadow/] && !filename[/_shadow/])
      return prefix + name + crack + extension
    end
    species = species_data.id.to_s
    female = "_female" if name[/f/]
    shadow = "_shadow" if name[/_shadow/]
    return prefix + species + form + female + shadow + egg_icon + crack + extension
  end
  
  def convert_symbol_to_number(src_dir, filename, default_prefix = "")
    name = filename
    extension = ".png"
    if filename[/^(.+)\.([^\.]+)$/]   # Of the format something.abc
      name = $~[1]
      extension = "." + $~[2]
    end
    previous_folder = src_dir.split("/")[-1]
    prefix = default_prefix
    egg = form = female = shadow = crack = back = shiny = ""
    if default_prefix == "" && !USE_ROOT
      if previous_folder[/shiny/]
        prefix = (name[/b/] || previous_folder[/Back/]) ? "Back shiny/" : "Front shiny/"
      else
        prefix = (name[/b/] || previous_folder[/Back/]) ? "Back/" : "Front/"
      end
    elsif default_prefix == "Icons/"
      prefix = "Icons shiny/" if name[/s/] && !name[/shadow/]
    end
    if previous_folder[/Eggs/]
      prefix = "Eggs/" if !USE_ROOT
      prefix = "Icons/" if USE_ROOT && name[/_icon/]
      egg = "egg"
      prefix = prefix+"icon" if name[/_icon/]
      # crack = "_icon" if default_prefix == "Icons/"
      # crack = "Cracks" if name[/_cracks/]
    end
    prefix = prefix+"icon" if previous_folder[/Icons/]
    shadow = "_shadow" if name[/_shadow/]
    prefix = "Shadow/" if previous_folder[/Shadow/]
    species_symbol = name.gsub("_female","").gsub("_shadow","").gsub("egg","").gsub("_cracks","").gsub("_icon","")
    species_data = GameData::Species.try_get(species_symbol)
    if !species_data
      if egg != ""
        if name == "000_icon"
          return "#{USE_ROOT ? "Icons/" : "Eggs/"}iconEgg"+extension
        elsif name == "000"
          return "#{USE_ROOT ? "" : "Eggs/"}/egg"+extension
        end
      end
      return prefix + name + egg + shadow + crack + extension
    end
    species = getFormattedNumber(species_data.species)
    form = "_" + $~[1].to_s if name[/_(\d+)$/] || name[/_(\d+)\D/]
    female = "f" if name[/_female/]
    shiny = "s" if previous_folder[/shiny/]
    back = "b" if previous_folder[/Back/]
    prefix = prefix+"footprint" if previous_folder[/Footprints/]
    return prefix + species + female + shiny + back + egg + form + shadow + crack + extension
  end

  def convert_pokemon_sprites(symbol_to_number, src_dir, dest_dir)
    return if !FileTest.directory?(src_dir)
    # generates a list of all graphic files
    files = readDirectoryFiles(src_dir, ["*.png"])
    # starts automatic renaming
    files.each_with_index do |file, i|
      Graphics.update if i % 100 == 0
      pbSetWindowText(_INTL("Converting Pokémon sprites {1}/{2}...", i, files.length)) if i % 50 == 0
      # next if !file[/^\d+[^\.]*\.[^\.]*$/]
      new_filename = convert_pokemon_filename(symbol_to_number, src_dir, file)
      # moves the files into their appropriate folders
      File.copy(src_dir + file, dest_dir + new_filename)
      break if i==CONVERT_QUANTITY
    end
  end

  def convert_pokemon_icons(symbol_to_number, src_dir, dest_dir)
    return if !FileTest.directory?(src_dir)
    # generates a list of all graphic files
    files = readDirectoryFiles(src_dir, ["*.png"])
    # starts automatic renaming
    files.each_with_index do |file, i|
      Graphics.update if i % 100 == 0
      pbSetWindowText(_INTL("Converting Pokémon icons {1}/{2}...", i, files.length)) if i % 50 == 0
      # next if !file[/^icon\d+[^\.]*\.[^\.]*$/]
      new_filename = convert_pokemon_filename(symbol_to_number, src_dir, file.sub(/^icon/, ''), "Icons/")
      # moves the files into their appropriate folders
      File.copy(src_dir + file, dest_dir + new_filename)
      break if i==CONVERT_QUANTITY
    end
  end

  def convert_pokemon_footprints(symbol_to_number, src_dir, dest_dir)
    return if !FileTest.directory?(src_dir)
    # generates a list of all graphic files
    files = readDirectoryFiles(src_dir, ["*.png"])
    # starts automatic renaming
    files.each_with_index do |file, i|
      Graphics.update if i % 100 == 0
      pbSetWindowText(_INTL("Converting footprints {1}/{2}...", i, files.length)) if i % 50 == 0
      new_filename = convert_pokemon_filename(symbol_to_number, src_dir, file.sub(/^footprint/, ''), "Footprints/")
      # moves the files into their appropriate folders
      File.copy(src_dir + file, dest_dir + new_filename)
      break if i==CONVERT_QUANTITY
    end
  end

  def convert_pokemon_cries(symbol_to_number, src_dir, dest_dir)
    return if !FileTest.directory?(src_dir)
    # generates a list of all audio files
    files = readDirectoryFiles(src_dir, ["*.wav", "*.mp3", "*.ogg"])
    # starts automatic renaming
    files.each_with_index do |file, i|
      Graphics.update if i % 100 == 0
      pbSetWindowText(_INTL("Converting Pokémon cries {1}/{2}...", i, files.length)) if i % 50 == 0
      if file[/^(\d+)Cry[^\.]*\.([^\.]*)$/]
        species = $~[1]
        extension = $~[2]
      else
        species = file.split(".")[0]
        extension = file.split(".")[1]
      end
      form = (file[/_(\d+)\./]) ? sprintf("_%s", $~[1]) : ""
      species_data = GameData::Species.try_get(symbol_to_number ? species.to_sym : species_per_number[species.to_i])
      cry_label = symbol_to_number ? "Cry" : ""
      if species_data
        species = symbol_to_number ? getFormattedNumber(species_data.id) : species_data.id.to_s
        File.copy(src_dir + file, dest_dir + species + cry_label + form + "." + extension)
      end
      break if i==CONVERT_QUANTITY
    end
  end
end

module GameData
  class Species
    class << self
      alias :old_check_graphic_file :check_graphic_file
      def check_graphic_file(path, species, form = 0, gender = 0, shiny = false, shadow = false, subfolder = "")
        return old_check_graphic_file(path, species, form, gender, shiny, shadow, subfolder) if !FileNumber::ENABLED
        try_subfolder = ""
        if !FileNumber::USE_ROOT || (subfolder!="Front" && subfolder!="Back")
          try_subfolder = sprintf("%s/", subfolder) 
        end
        try_species = getFormattedNumber(species)
        try_form    = (form > 0) ? sprintf("_%d", form) : ""
        try_gender  = (gender == 1) ? "f" : ""
        try_shiny  = (shiny) ? "s" : ""
        try_shadow  = (shadow) ? "_shadow" : ""
        try_back = (subfolder=="Back") ? "b" : ""
        factors = []
        factors.push([6, try_back, ""]) if try_back!=""
        if shiny
          if FileNumber::USE_ROOT
            factors.push([5, try_shiny, ""])
          else
            factors.push([4, sprintf("%s shiny/", subfolder), try_shiny])
          end
        end
        factors.push([3, try_shadow, ""]) if shadow
        factors.push([2, try_gender, ""]) if gender == 1
        factors.push([1, try_form, ""]) if form > 0
        factors.push([0, try_species, "000"])
        # Go through each combination of parameters in turn to find an existing sprite
        (2**factors.length).times do |i|
          # Set try_ parameters for this combination
          factors.each_with_index do |factor, index|
            value = ((i / (2**index)).even?) ? factor[1] : factor[2]
            case factor[0]
            when 0 then try_species   = value
            when 1 then try_form      = value
            when 2 then try_gender    = value
            when 3 then try_shadow    = value
            when 4 then try_subfolder = value   # Shininess
            when 5 then try_shiny     = value   # Shininess
            when 6 then try_back     = value
            end
          end
          # Look for a graphic matching this combination's parameters
          try_species_text = try_species
          try_species_text = "icon" + try_species_text if subfolder=="Icons" 
          ret = pbResolveBitmap(sprintf(
            "%s%s%s%s%s%s%s%s",
            path, try_subfolder, try_species_text, try_gender, try_shiny, try_back, try_form, try_shadow
          ))
          return ret if ret
        end
        return pbResolveBitmap("Graphics/Pokemon/Icons/000") if subfolder=="Icons"
        return nil
      end

      alias :old_check_egg_graphic_file :check_egg_graphic_file
      def check_egg_graphic_file(path, species, form, prefix = "")
        return old_check_egg_graphic_file(path, species, form, prefix) if !FileNumber::ENABLED
        species_data = self.get_species_form(species, form)
        return nil if species_data.nil?
        if form > 0
          ret = pbResolveBitmap(sprintf("%s%s%segg_%d", path, prefix, getFormattedNumber(species_data.species), form))
          return ret if ret
        end
        return pbResolveBitmap(sprintf("%s%s%segg", path, prefix, getFormattedNumber(species_data.species)))
      end

      alias :old_egg_sprite_filename :egg_sprite_filename
      def egg_sprite_filename(species, form)
        return old_egg_sprite_filename(species, form) if !FileNumber::ENABLED
        prefix = FileNumber::USE_ROOT ? "" : "Eggs/"
        ret = self.check_egg_graphic_file("Graphics/Pokemon/#{prefix}", species, form)
        return (ret) ? ret : pbResolveBitmap("Graphics/Pokemon/#{prefix}egg")
      end

      alias :old_egg_icon_filename :egg_icon_filename
      def egg_icon_filename(species, form)
        return old_egg_icon_filename(species, form) if !FileNumber::ENABLED
        prefix = FileNumber::USE_ROOT ? "Icons/" : "Eggs/"
        ret = self.check_egg_graphic_file("Graphics/Pokemon/#{prefix}", species, form, "icon")
        return (ret) ? ret : pbResolveBitmap("Graphics/Pokemon/#{prefix}iconEgg")
      end

      alias :old_footprint_filename :footprint_filename
      def footprint_filename(species, form = 0)
        return old_footprint_filename(species, form) if !FileNumber::ENABLED
        species_data = self.get_species_form(species, form)
        return nil if species_data.nil?
        if form > 0
          ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Footprints/footprint%s_%d", getFormattedNumber(species_data.species), form))
          return ret if ret
        end
        return pbResolveBitmap(sprintf("Graphics/Pokemon/Footprints/footprint%s", getFormattedNumber(species_data.species)))
      end

      alias :old_shadow_filename :shadow_filename
      def shadow_filename(species, form = 0)
        return old_shadow_filename(species, form) if !FileNumber::ENABLED
        species_data = self.get_species_form(species, form)
        return nil if species_data.nil?
        # Look for species-specific shadow graphic
        if form > 0
          ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s_%d_shadow", getFormattedNumber(species_data.species),form))
          return ret if ret
        end
        ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s_shadow",getFormattedNumber(species_data.species)))
        return ret if ret
        # Use general shadow graphic
        metrics_data = GameData::SpeciesMetrics.get_species_form(species_data.species, form)
        return pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%d", metrics_data.shadow_size))
      end

      alias :old_check_cry_file :check_cry_file
      def check_cry_file(species, form, suffix = "")
        return old_check_cry_file(species, form, suffix) if !FileNumber::ENABLED
        species_data = self.get_species_form(species, form)
        return nil if species_data.nil?
        if form > 0
          ret = sprintf("Cries/%sCry_%d%s", getFormattedNumber(species_data.species), form, suffix)
          return ret if pbResolveAudioSE(ret)
        end
        ret = sprintf("Cries/%sCry%s", getFormattedNumber(species_data.species), suffix)
        return (pbResolveAudioSE(ret)) ? ret : nil
      end
      
      def getFormattedNumber(species)
        return FileNumber.getFormattedNumber(species)
      end
    end
  end
end

MenuHandlers.add(:debug_menu, :files_symbol_to_number, {
  "name"        => _INTL("Convert Pokémon symbols to numbers"),
  "parent"      => :other_menu,
  "description" => _INTL("Convert Pokémon files symbols to number on a new folder."),
  "effect"      => proc {
    msgwindow = pbCreateMessageWindow
    if !pbConfirmMessage(_INTL("Are you sure?"))
      pbDisposeMessageWindow(msgwindow)
      next
    end
    FileNumber.convert_files(true)
    pbDisposeMessageWindow(msgwindow)
  }
})

MenuHandlers.add(:debug_menu, :files_number_to_symbol, {
  "name"        => _INTL("Convert Pokémon numbers to symbols"),
  "parent"      => :other_menu,
  "description" => _INTL("Convert Pokémon files number to symbols on a new folder."),
  "effect"      => proc {
    msgwindow = pbCreateMessageWindow
    if !pbConfirmMessage(_INTL("Are you sure?"))
      pbDisposeMessageWindow(msgwindow)
      next
    end
    FileNumber.convert_files(false)
    pbDisposeMessageWindow(msgwindow)
  }
})