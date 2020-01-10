if self.class.respond_to?(:loaded_features)
  self.class.loaded_features << :feature_one
end
