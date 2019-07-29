class AddDerivedEstimatedHoursToWorkPackages < ActiveRecord::Migration[5.2]
  class WorkPackageWithRelations < ActiveRecord::Base
    self.table_name = WorkPackage.table_name

    scope :with_children, ->(*args) do
      rel = Relation.table_name
      wp = WorkPackage.table_name

      query = "EXISTS (SELECT 1 FROM #{rel} WHERE #{rel}.from_id = #{wp}.id AND #{rel}.hierarchy > 0 LIMIT 1)"

      where(query)
    end
  end

  def change
    add_column :work_packages, :derived_estimated_hours, :float

    reversible do |change|
      change.up do
        # Before this migration all work packages who have children had their
        # estimated hours set based on their children through the UpdateAncestorsService.
        #
        # We move this value to the derived_estimated_hours column and clear
        # the estimated_hours column. In the future users can estimte the time
        # for parent work pacages separately there while the UpdateAncestorsService
        # only touches the derived_estimated_hours column.
        WorkPackageWithRelations
          .with_children
          .update_all("derived_estimated_hours = estimated_hours, estimated_hours = NULL")
      end
    end
  end
end
