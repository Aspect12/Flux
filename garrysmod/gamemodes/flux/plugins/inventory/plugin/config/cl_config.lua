local category = config.create_category('inventory', 'config.inventory.title', 'config.inventory.desc')
category.add_slider('inventory_width', 'config.inventory.width.name', 'config.inventory.width.desc', { min = 1, max = 64, default = 8 })
category.add_slider('invendory_height', 'config.inventory.height.name', 'config.inventory.height.desc', { min = 1, max = 64, default = 6 })
category.add_slider('hotbar_width', 'config.inventory.hotbar_width.name', 'config.inventory.hotbar_width.desc', { min = 1, max = 64, default = 8 })
category.add_slider('hotbar_height', 'config.inventory.hotbar_height.name', 'config.inventory.hotbar_height.desc', { min = 1, max = 64, default = 1 })
