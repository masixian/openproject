class AddDerivedEstimatedHoursToWorkPackages < ActiveRecord::Migration[5.2]
  def change
    add_column :work_packages, :derived_estimated_hours, :float
  end
end
