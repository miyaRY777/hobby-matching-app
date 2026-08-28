module TagInputHelpers
  def add_new_hobby_tag(name)
    fill_in "tag-input", with: name
    find("[data-testid='new-tag-add-row']").click
  end
end
