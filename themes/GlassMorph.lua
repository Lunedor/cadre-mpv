--[[
=========================================================
 cadre_theme.lua
 Obsidian Glass Configuration
=========================================================
]]

local mp = require "mp"
local msg = require "mp.msg"
local M = {}

M.theme_name = "Obsidian Glass"
M.theme_author = "Custom"
M.theme_variant = "ObsidianGlass" 

----------------------------------------------------------
-- 1. CORE PALETTE (Global Base)
----------------------------------------------------------
M.accent_color     = "5C88F2" 
M.background_color = "0D1017" 
M.surface_color    = "161A22" 
M.text_color       = "E6EDF3" 
M.dim_color        = "64748B" 
M.danger_color     = "EF4444" 

----------------------------------------------------------
-- 2. GLOBAL TYPOGRAPHY & OPACITY
----------------------------------------------------------
M.font_text       = "Inter"                      
M.font_size       = 16                           
M.title_font_size = 18                           
M.font_icon       = "Material Icons Round"    
M.alpha_bar_bg    = "40"                         
M.alpha_icon_dim  = "70"                         

----------------------------------------------------------
-- 3. TITLE BAR (_tb)
----------------------------------------------------------
M.titlebar_show_mode       = "auto"
M.titlebar_button_side     = "right"
M.bar_height_tb            = 36      
M.button_width_tb          = 44      
M.hover_strip_height_tb    = 10      
M.hide_delay_sec_tb        = 0.35    
M.maximize_cooldown_sec_tb = 0.3     
M.title_font_size_tb       = 14      
M.font_icon_tb             = "Segoe MDL2 Assets" 
M.color_bar_bg_tb          = "0D1017"            
M.alpha_bar_bg_tb          = "40"                
M.color_text_tb            = "E2E8F0"            
M.color_hover_bg_tb        = "161A22"            
M.color_danger_tb          = "EF4444"            

----------------------------------------------------------
-- 4. ON-SCREEN CONTROLLER (_osc) (Play Bar)
----------------------------------------------------------
M.bar_height_osc       = 100       
M.bar_side_inset_osc   = 24       
M.bar_y_anchor_osc     = "bottom" 
M.bar_top_inset_osc    = 24       
M.bar_bottom_inset_osc = 24       
M.bar_radius_osc       = 16       
M.bar_autohide_sec_osc = 0.4      
M.color_bar_bg_osc     = "0D1017" 
M.alpha_bar_bg_osc     = "40"     

-- Seekbar
M.seek_y_offset         = 18       
M.side_margin           = 16       
M.seek_side_inset_osc   = 16       
M.seek_height_normal    = 6        
M.seek_height_hover     = 10       
M.color_track_fg_osc    = "5C88F2" 
M.color_track_bg_osc    = "21262D" 
M.color_slider_rail_osc = "21262D" 
M.seek_border_width_osc = 1        
M.seek_border_color_osc = "2A2E37" 
M.seek_border_alpha_osc = "60"     

-- Thumb
M.thumb_width           = 10         
M.thumb_height          = 10         
M.thumb_radius          = 7          
M.thumb_color           = "F8FAFC"   
M.thumb_border_width_osc = 1         
M.thumb_border_color_osc = "000000"  
M.thumb_border_alpha_osc = "40"      

-- Time Labels
M.time_label_offset_y         = 18           
M.font_size_osc               = 20           
M.color_text_osc              = "E6EDF3"     
M.time_item_width_osc         = 140          
M.time_label_shadow_osc       = true         
M.time_label_shadow_x_osc     = 0            
M.time_label_shadow_y_osc     = 2            
M.time_label_shadow_color_osc = "000000"     
M.time_label_shadow_alpha_osc = "80"         
M.time_label_outline_osc       = false        

-- Neumorphic Buttons
M.icon_size               = 24       
M.icon_spacing            = 48       
M.button_row_offset       = 52       
M.color_icon_osc          = "E6EDF3" 
M.alpha_icon_dim_osc      = "00"     
M.icon_bg_enabled_osc     = true     
M.icon_bg_color_osc       = "161A22" 
M.icon_bg_alpha_osc       = "A0"     
M.icon_bg_pad_x_osc       = 10        
M.icon_bg_height_osc      = 40       
M.icon_bg_radius_osc      = 12       
M.icon_border_enabled_osc = true     
M.icon_border_width_osc   = 1        
M.icon_border_color_osc   = "2A2E37" 
M.icon_border_alpha_osc   = "AA"     
M.button_row_offset 	  = 70
-- Volume Slider
M.volume_slider_mute_osc = true                  
M.volume_slider_width_osc = 110                  
M.volume_slider_height_osc = 6                   
M.volume_slider_thumb_width_osc = 4              
M.volume_slider_thumb_height_osc = 12            
M.volume_slider_radius_osc = 3                   
M.volume_slider_color_osc = "5C88F2"             
M.volume_slider_track_color_osc = "21262D"       
M.volume_slider_mute_width_osc = 24              
M.volume_slider_mute_gap_osc = 8                 

----------------------------------------------------------
-- 5. PLAYLIST PANEL (_pl)
----------------------------------------------------------
M.row_padding_x_pl       = 16      
M.row_gap_pl             = 4       
M.row_radius_pl          = 8       
M.title_offset_x_pl      = 42      
M.row_right_inset_x_pl   = 16      
M.color_hover_pl         = "161A22" 
M.alpha_hover_pl         = "80"    
M.alpha_selected_pl      = "A0"    
M.alpha_current_pl       = "C0"    
M.color_index_pl         = "64748B" 
M.alpha_index_pl         = "30"    
M.color_duration_pl      = "64748B" 
M.alpha_duration_pl      = "00"    
M.icon_size_pl           = 18      
M.toolbar_icon_size_pl   = 20      
M.toolbar_icon_spacing_pl = 34     

M.panel_width_pl       = 420		 
M.row_height_pl        = 42 		 
M.header_height_pl     = 42 		 
M.toolbar_height_pl    = 42 		 
M.search_height_pl     = 40		  
M.bar_radius_pl        = 16 		 
M.font_size_pl         = 14 		 
M.title_font_size_pl   = 16 		 

M.side_inset_pl        = 16      
M.top_inset_pl         = 48      
M.bottom_inset_pl      = 145     
M.osc_bottom_exclusion_pl = 125  

M.scrollbar_width_pl   = 4       
M.hover_strip_width_pl = 16      
M.hide_delay_sec_pl    = 0.35    

M.font_icon_pl         = "Material Icons Outlined"   
M.color_bar_bg_pl      = "0D1017"                    
M.alpha_bar_bg_pl      = "40"                        
M.color_icon_pl        = "64748B"                    
M.color_text_pl        = "F8FAFC"                    
M.color_dim_pl         = "64748B"                    
M.color_danger_pl      = "EF4444"                    
M.color_scroll_fg_pl   = "2A2E37"                    
M.color_scroll_bg_pl   = "0B0E14"                    
M.color_selected_pl    = "5C88F2"                    
M.color_current_pl     = "5C88F2"                    
M.alpha_icon_dim_pl    = "60"                        


return M