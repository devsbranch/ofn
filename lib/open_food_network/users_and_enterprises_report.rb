module OpenFoodNetwork
  class UsersAndEnterprisesReport
    attr_reader :params
    def initialize(params = {})
      @params = params
    end

    def header
      [
          "User",
          "Relationship",
          "Enterprise",
          "Producer?",
          "Sells",
          "Confirmation Date"
        ]
    end

    def table
      users_and_enterprises.map do |uae| [
        uae["user_email"],
        uae["relationship_type"],
        uae["name"],
        to_bool(uae["is_primary_producer"]),
        uae["sells"],
        to_local_datetime(uae["confirmed_at"])
        ]
      end
    end

    def owners_and_enterprises
      ActiveRecord::Base.connection.execute("SELECT enterprises.name, enterprises.sells, enterprises.is_primary_producer, enterprises.confirmed_at,
      'owns' AS relationship_type, owners.email as user_email FROM enterprises
      LEFT JOIN spree_users AS owners ON owners.id=enterprises.owner_id ORDER BY enterprises.name DESC" )
      .to_a
    end

    def managers_and_enterprises
      ActiveRecord::Base.connection.execute("SELECT enterprises.name, enterprises.sells, enterprises.is_primary_producer, enterprises.confirmed_at,
      'manages' AS relationship_type, managers.email as user_email FROM enterprises
      LEFT JOIN enterprise_roles ON enterprises.id=enterprise_roles.enterprise_id
      LEFT JOIN spree_users AS managers ON enterprise_roles.user_id=managers.id
      WHERE enterprise_id IS NOT NULL
      AND user_id IS NOT NULL
      ORDER BY enterprises.name DESC, user_email DESC")
      .to_a
    end

    def users_and_enterprises
      sort( owners_and_enterprises.concat managers_and_enterprises )
    end

    def sort(results)
      results.sort do |a,b|
        [ a["name"], b["relationship_type"], a["user_email"] ] <=>
        [ b["name"], a["relationship_type"], b["user_email"] ]
      end
    end

    def to_bool(value)
      ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
    end

    def to_local_datetime(string)
      return "Not Confirmed" if string.nil?
      string.to_datetime.in_time_zone.strftime "%Y-%m-%d %H:%M"
    end
  end
end