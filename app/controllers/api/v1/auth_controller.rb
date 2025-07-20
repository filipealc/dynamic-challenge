class Api::V1::AuthController < Api::V1::BaseController
  def me
    render_success({
      user: {
        id: current_user.id,
        name: current_user.name,
        email: current_user.email,
        picture: current_user.picture,
        created_at: current_user.created_at
      },
      wallets_count: current_user.wallets.count,
      total_balance: current_user.wallets.sum(&:balance)
    })
  end
end
